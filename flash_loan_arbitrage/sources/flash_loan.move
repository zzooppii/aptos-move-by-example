module ArbitrageAddr::flash_loan {
    use aptos_framework::coin;
    use std::signer;

    /// 에러 코드
    const EPOOL_ALREADY_INITIALIZED: u64 = 1;
    const ENOT_ADMIN: u64 = 2;
    const EINSUFFICIENT_LIQUIDITY: u64 = 3;
    const EINVALID_REPAY_AMOUNT: u64 = 4;

    /// 플래시론 대출 풀
    struct LoanPool<phantom CoinType> has key {
        liquidity: coin::Coin<CoinType>,
        fee_numerator: u64,
        fee_denominator: u64,
    }

    /// Hot Potato: 복사(copy), 버림(drop), 저장(store) 능력이 없는 순수 영수증 구조체
    /// 이 영수증이 생성되면, 트랜잭션 종료 전에 `repay_loan`에서 소비(destruct)되어야만 합니다.
    struct Receipt<phantom CoinType> {
        amount_borrowed: u64,
        fee_amount: u64,
    }

    /// 풀 초기화 (어드민만)
    public entry fun initialize_loan_pool<CoinType>(
        admin: &signer,
        fee_numerator: u64,
        fee_denominator: u64
    ) {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == @ArbitrageAddr, ENOT_ADMIN);
        assert!(!exists<LoanPool<CoinType>>(admin_addr), EPOOL_ALREADY_INITIALIZED);

        move_to(admin, LoanPool<CoinType> {
            liquidity: coin::zero<CoinType>(),
            fee_numerator,
            fee_denominator,
        });
    }

    /// 테스트용: 관리자가 시작 시 풀에 유동성 추가
    public entry fun add_liquidity<CoinType>(
        admin: &signer,
        amount: u64,
    ) acquires LoanPool {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == @ArbitrageAddr, ENOT_ADMIN);
        
        let pool = borrow_global_mut<LoanPool<CoinType>>(@ArbitrageAddr);
        let coin_in = coin::withdraw<CoinType>(admin, amount);
        coin::merge(&mut pool.liquidity, coin_in);
    }

    /// 대출 요청 함수
    /// 사용자가 금액을 요청하면, 자산(Coin)과 함께 반드시 갚아야 하는 'Receipt'를 반환합니다.
    public fun request_loan<CoinType>(
        amount: u64
    ): (coin::Coin<CoinType>, Receipt<CoinType>) acquires LoanPool {
        let pool = borrow_global_mut<LoanPool<CoinType>>(@ArbitrageAddr);
        
        // 풀 잔고가 충분한지 확인
        let pool_balance = coin::value(&pool.liquidity);
        assert!(pool_balance >= amount, EINSUFFICIENT_LIQUIDITY);

        // 수수료 계산
        let fee_amount = (amount * pool.fee_numerator) / pool.fee_denominator;

        // Hot Potato 생성
        let receipt = Receipt<CoinType> {
            amount_borrowed: amount,
            fee_amount,
        };

        // 대출금 출금 및 반환
        let loaned_coin = coin::extract(&mut pool.liquidity, amount);
        
        (loaned_coin, receipt)
    }

    /// 대출 상환 함수
    /// 사용자는 빌린 자산 + 수수료와, 자신이 받았던 'Receipt'를 넣어서 상환해야 합니다.
    /// 이 함수가 성공적으로 실행되면 Receipt는 내부적으로 파괴(언패킹)됩니다.
    public fun repay_loan<CoinType>(
        repayment: coin::Coin<CoinType>,
        receipt: Receipt<CoinType>
    ) acquires LoanPool {
        let Receipt { amount_borrowed, fee_amount } = receipt; // 영수증 파괴 (언패킹)
        
        // 갚아야 할 총 금액 확인
        let exact_repay_amount = amount_borrowed + fee_amount;
        let actual_repay_amount = coin::value(&repayment);
        assert!(actual_repay_amount == exact_repay_amount, EINVALID_REPAY_AMOUNT);

        // 대출 풀에 자산 돌려놓기
        let pool = borrow_global_mut<LoanPool<CoinType>>(@ArbitrageAddr);
        coin::merge(&mut pool.liquidity, repayment);
    }

    /// 영수증으로부터 상환할 금액을 볼 수 있는 헬퍼 함수
    public fun get_repay_amount<CoinType>(receipt: &Receipt<CoinType>): u64 {
        receipt.amount_borrowed + receipt.fee_amount
    }
}
