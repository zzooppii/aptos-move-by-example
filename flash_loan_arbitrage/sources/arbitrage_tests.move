#[test_only]
module ArbitrageAddr::arbitrage_tests {
    use aptos_framework::account;
    use std::signer;
    use aptos_framework::coin;
    
    use ArbitrageAddr::coins::{Self, CoinA, CoinB};
    use ArbitrageAddr::mock_dex;
    use ArbitrageAddr::mock_dex_2;
    use ArbitrageAddr::flash_loan;
    use ArbitrageAddr::arbitrage;

    const EARBITRAGE_FAILED: u64 = 1;

    // 테스트 환경 셋업 헬퍼 함수
    fun setup_test(admin: &signer, user: &signer, aptos_framework: &signer) {
        let admin_addr = signer::address_of(admin);

        // 1. Aptos 프레임워크 초기화 (테스트용)
        account::create_account_for_test(signer::address_of(aptos_framework));
        coin::create_coin_conversion_map(aptos_framework);

        account::create_account_for_test(admin_addr);
        account::create_account_for_test(signer::address_of(user));

        // 2. 코인 모듈 초기화
        coins::initialize(admin);

        // 3. 플래시론 풀 초기화 및 유동성 공급 (수수료 0.1% -> 1/1000)
        flash_loan::initialize_loan_pool<CoinA>(admin, 1, 1000); 
        
        // 대출 풀 유동성: 10,000,000 CoinA
        coins::mint_coin_a(admin, 10000000);
        flash_loan::add_liquidity<CoinA>(admin, 10000000);

        // 4. DEX 1: 1A = 1.5B 비율이라고 가정
        // 수수료 0%로 간소화 (0/1000)
        mock_dex::initialize_pool<CoinA, CoinB>(admin, 0, 1000);
        coins::mint_coin_a(admin, 1000000); // 1,000,000 A
        coins::mint_coin_b(admin, 1500000); // 1,500,000 B
        mock_dex::add_liquidity<CoinA, CoinB>(admin, 1000000, 1500000);

        // 5. DEX 2: 1A = 0.8B 비율이라고 가정 (즉 B가 더 비쌈, 1.25배 가치)
        // 수수료 0%로 간소화
        mock_dex_2::initialize_pool<CoinA, CoinB>(admin, 0, 1000);
        coins::mint_coin_a(admin, 2000000); // 2,000,000 A
        coins::mint_coin_b(admin, 1600000); // 1,600,000 B
        mock_dex_2::add_liquidity<CoinA, CoinB>(admin, 2000000, 1600000);
    }

    #[test(admin = @ArbitrageAddr, user = @0x123, aptos_framework = @0x1)]
    fun test_successful_arbitrage(admin: &signer, user: &signer, aptos_framework: &signer) {
        setup_test(admin, user, aptos_framework);
        
        let user_addr = signer::address_of(user);

        // 차익 거래 실행 전 잔고 (0A)
        if (coin::is_account_registered<CoinA>(user_addr)) {
            assert!(coin::balance<CoinA>(user_addr) == 0, 0);
        };

        // 빌릴 금액: 100,000 A
        // 플래시론 수수료 0.1%: 100 A -> 갚아야 할 총 금액: 100,100 A
        
        // DEX1 예상 스왑 (1A -> 1.5B 풀) 
        // 입력: 100,000 A.  풀방식: K = 1,000,000 * 1,500,000 = 1,500,000,000,000
        // X = 1,100,000. Y출력 = 1500000 - (K / 1100000) = 1500000 - 1363636 = 136,364 B 획득 예상
        
        // DEX2 예상 스왑 (B -> A, 1.25A 풀)
        // 입력: 136,363 B. 풀방식: K = 2,000,000 * 1,600,000 = 3,200,000,000,000
        // Y = 1,600,000 + 136,363 = 1,736,363
        // X출력 = 2000000 - (K / 1736363) = 2000000 - 1842932 = 157,068 A 획득 예상

        // 결론: 갚을 돈은 100,100 A 인데 번 돈이 157,068 A 임으로 차익 발생!
        arbitrage::execute_arbitrage(user, 100000);

        // 성공 검증
        let final_balance = coin::balance<CoinA>(user_addr);
        // 수익 = 157,068 - 100,100 = 56,968 A 정도가 등록되어야 함.
        assert!(final_balance > 0, 1); 
    }

    #[test(admin = @ArbitrageAddr, user = @0x123, aptos_framework = @0x1)]
    #[expected_failure(abort_code = 1, location = ArbitrageAddr::arbitrage)]
    fun test_failed_arbitrage_reverts(admin: &signer, user: &signer, aptos_framework: &signer) {
        setup_test(admin, user, aptos_framework);
        
        // 실패 시뮬레이션을 위해 대출 금액을 무리하게 설정
        // 풀 보유량 대비 과도한 금액을 스왑하면 슬리피지가 엄청 커져서 무조건 손해를 봄
        // 빌릴 금액: 5,000,000 A
        // 플래시론 수수료 0.1%: 5,000 A -> 갚아야할 돈 5,005,000 A
        
        // DEX1 풀규모보다 큰 요청이므로 손실 발생하여 상환조차 안됨.
        // 여기서 EARBITRAGE_FAILED (abort_code 1) 이 발생해야 함.
        arbitrage::execute_arbitrage(user, 5000000);
    }
}
