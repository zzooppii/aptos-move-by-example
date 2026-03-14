module ArbitrageAddr::mock_dex {
    use aptos_framework::coin;
    use std::signer;
    
    /// DEX 에러 코드
    const EPOOL_NOT_INITIALIZED: u64 = 1;
    const EPOOL_ALREADY_INITIALIZED: u64 = 2;
    const EINSUFFICIENT_OUTPUT_AMOUNT: u64 = 3;
    const EINSUFFICIENT_LIQUIDITY: u64 = 4;
    const ENOT_ADMIN: u64 = 5;

    /// 가상의 유동성 풀 구조체
    /// CoinX 와 CoinY 의 잔고를 보관합니다.
    struct LiquidityPool<phantom CoinX, phantom CoinY> has key {
        coin_x: coin::Coin<CoinX>,
        coin_y: coin::Coin<CoinY>,
        reserve_x: u64,
        reserve_y: u64,
        fee_numerator: u64,
        fee_denominator: u64,
    }

    /// 쌍(Pair) 초기화 함수. 
    /// (실제 DEX라면 누구나 만들 수 있지만, 시뮬레이션을 위해 어드민만 생성 가능하도록 설정)
    public entry fun initialize_pool<CoinX, CoinY>(
        admin: &signer,
        fee_numerator: u64,
        fee_denominator: u64
    ) {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == @ArbitrageAddr, ENOT_ADMIN);
        assert!(!exists<LiquidityPool<CoinX, CoinY>>(admin_addr), EPOOL_ALREADY_INITIALIZED);

        move_to(admin, LiquidityPool<CoinX, CoinY> {
            coin_x: coin::zero<CoinX>(),
            coin_y: coin::zero<CoinY>(),
            reserve_x: 0,
            reserve_y: 0,
            fee_numerator,
            fee_denominator,
        });
    }

    /// 풀에 초기 유동성을 공급하는 함수 (간소화)
    public entry fun add_liquidity<CoinX, CoinY>(
        provider: &signer,
        amount_x: u64,
        amount_y: u64
    ) acquires LiquidityPool {
        let pool = borrow_global_mut<LiquidityPool<CoinX, CoinY>>(@ArbitrageAddr);
        
        let coin_x_in = coin::withdraw<CoinX>(provider, amount_x);
        let coin_y_in = coin::withdraw<CoinY>(provider, amount_y);

        pool.reserve_x = pool.reserve_x + amount_x;
        pool.reserve_y = pool.reserve_y + amount_y;

        coin::merge(&mut pool.coin_x, coin_x_in);
        coin::merge(&mut pool.coin_y, coin_y_in);
    }

    /// X를 넣고 Y를 받는 Swap
    /// Constant Product 공식을 간소화하여 사용 (x * y = k)
    /// 반환값: 교환된 Y 코인
    public fun swap_x_to_y_direct<CoinX, CoinY>(
        coin_in: coin::Coin<CoinX>
    ): coin::Coin<CoinY> acquires LiquidityPool {
        let amount_in = coin::value(&coin_in);
        assert!(amount_in > 0, EINSUFFICIENT_OUTPUT_AMOUNT);
        
        let pool = borrow_global_mut<LiquidityPool<CoinX, CoinY>>(@ArbitrageAddr);
        assert!(pool.reserve_x > 0 && pool.reserve_y > 0, EINSUFFICIENT_LIQUIDITY);

        // 수수료 차감 후 입력 금액 계산
        let amount_in_with_fee = amount_in * (pool.fee_denominator - pool.fee_numerator);
        let numerator = amount_in_with_fee * pool.reserve_y;
        let denominator = (pool.reserve_x * pool.fee_denominator) + amount_in_with_fee;
        
        let amount_out = numerator / denominator;
        assert!(amount_out > 0, EINSUFFICIENT_OUTPUT_AMOUNT);
        assert!(pool.reserve_y > amount_out, EINSUFFICIENT_LIQUIDITY);

        // 풀 상태 업데이트
        pool.reserve_x = pool.reserve_x + amount_in;
        pool.reserve_y = pool.reserve_y - amount_out;

        // 코인 교환
        coin::merge(&mut pool.coin_x, coin_in);
        coin::extract(&mut pool.coin_y, amount_out)
    }

    /// Y를 넣고 X를 받는 Swap
    public fun swap_y_to_x_direct<CoinX, CoinY>(
        coin_in: coin::Coin<CoinY>
    ): coin::Coin<CoinX> acquires LiquidityPool {
        let amount_in = coin::value(&coin_in);
        assert!(amount_in > 0, EINSUFFICIENT_OUTPUT_AMOUNT);
        
        let pool = borrow_global_mut<LiquidityPool<CoinX, CoinY>>(@ArbitrageAddr);
        assert!(pool.reserve_x > 0 && pool.reserve_y > 0, EINSUFFICIENT_LIQUIDITY);

        // 수수료 차감 후 입력 금액 계산
        let amount_in_with_fee = amount_in * (pool.fee_denominator - pool.fee_numerator);
        let numerator = amount_in_with_fee * pool.reserve_x;
        let denominator = (pool.reserve_y * pool.fee_denominator) + amount_in_with_fee;
        
        let amount_out = numerator / denominator;
        assert!(amount_out > 0, EINSUFFICIENT_OUTPUT_AMOUNT);
        assert!(pool.reserve_x > amount_out, EINSUFFICIENT_LIQUIDITY);

        // 풀 상태 업데이트
        pool.reserve_y = pool.reserve_y + amount_in;
        pool.reserve_x = pool.reserve_x - amount_out;

        // 코인 교환
        coin::merge(&mut pool.coin_y, coin_in);
        coin::extract(&mut pool.coin_x, amount_out)
    }
}
