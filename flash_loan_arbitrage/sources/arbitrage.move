module ArbitrageAddr::arbitrage {
    use aptos_framework::coin;
    use std::signer;
    use ArbitrageAddr::coins::{CoinA, CoinB};
    use ArbitrageAddr::flash_loan;
    use ArbitrageAddr::mock_dex;

    const EARBITRAGE_FAILED: u64 = 1;

    /// 플래시론 차익거래 실행 함수 (단일 트랜잭션 내에서 모두 발생)
    /// 1. 플래시론 대출 (CoinA)
    /// 2. DEX1에서 스왑 (CoinA -> CoinB)
    /// 3. DEX2에서 스왑 (CoinB -> CoinA)
    /// 4. 플래시론 상환
    /// 5. 남은 이득은 호출자에게 귀속
    public entry fun execute_arbitrage(
        executor: &signer,
        borrow_amount: u64
    ) {
        // 1. 대출 실행 (빌린 자산과 영수증을 동시에 받음)
        let (borrowed_coin_a, receipt) = flash_loan::request_loan<CoinA>(borrow_amount);
        let repay_amount = flash_loan::get_repay_amount(&receipt);

        // 2. DEX 1 스왑 (가상의 교환비율 1:1.5라 가정하여 더 많은 CoinB 획득 기대)
        let exchanged_coin_b = mock_dex::swap_x_to_y_direct<CoinA, CoinB>(borrowed_coin_a);

        // 3. DEX 2 스왑 (가상의 교환비율이 1:1이라 가정하여 차익 실현)
        let result_coin_a = ArbitrageAddr::mock_dex_2::swap_y_to_x_direct<CoinA, CoinB>(exchanged_coin_b);

        // 결과 검증: 플래시론을 갚고도 남는 지 확인
        let final_balance = coin::value(&result_coin_a);
        assert!(final_balance >= repay_amount, EARBITRAGE_FAILED); // 수익이 안나면 전체 트랜잭션 롤백! (아무 일도 일어나지 않음)

        // 4. 플래시론 상환용 금액 분리
        let repayment_coin = coin::extract(&mut result_coin_a, repay_amount);
        
        // 상환 실행 및 영수증 소각 (이 함수 호출을 누락하면 컴파일 혹은 런타임 에러 발생)
        flash_loan::repay_loan(repayment_coin, receipt);

        // 5. 남은 수익은 사용자 계정으로 입금
        let executor_addr = signer::address_of(executor);
        if (!coin::is_account_registered<CoinA>(executor_addr)) {
            coin::register<CoinA>(executor);
        };
        coin::deposit(executor_addr, result_coin_a);
    }
}
