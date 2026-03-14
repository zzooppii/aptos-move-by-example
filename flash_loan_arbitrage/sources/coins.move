module ArbitrageAddr::coins {
    use aptos_framework::coin;
    use aptos_framework::account;
    use std::string;
    use std::signer;

    /// 코인 모듈 초기화 에러
    const EALREADY_INITIALIZED: u64 = 1;
    const ENOT_ADMIN: u64 = 2;

    struct CoinA {}
    struct CoinB {}

    struct Caps<phantom CoinType> has key {
        mint_cap: coin::MintCapability<CoinType>,
        burn_cap: coin::BurnCapability<CoinType>,
        freeze_cap: coin::FreezeCapability<CoinType>,
    }

    /// 모듈 소유자(ArbitrageAddr)만 호출 가능한 초기화 함수
    public entry fun initialize(admin: &signer) {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == @ArbitrageAddr, ENOT_ADMIN);
        
        // CoinA 초기화
        let (a_burn_cap, a_freeze_cap, a_mint_cap) = coin::initialize<CoinA>(
            admin,
            string::utf8(b"CoinA"),
            string::utf8(b"CA"),
            8, // decimals
            true, // monitor_supply
        );
        
        move_to(admin, Caps<CoinA> { mint_cap: a_mint_cap, burn_cap: a_burn_cap, freeze_cap: a_freeze_cap });
        
        // CoinB 초기화
        let (b_burn_cap, b_freeze_cap, b_mint_cap) = coin::initialize<CoinB>(
            admin,
            string::utf8(b"CoinB"),
            string::utf8(b"CB"),
            8, // decimals
            true, // monitor_supply
        );

        move_to(admin, Caps<CoinB> { mint_cap: b_mint_cap, burn_cap: b_burn_cap, freeze_cap: b_freeze_cap });
    }

    /// 테스트 목적: 아무나 특정 코인을 민트할 수 있게 허용 (실제 프로덕션에서는 절대 이렇게 하면 안됨)
    public entry fun mint_coin_a(account: &signer, amount: u64) acquires Caps {
        let account_addr = signer::address_of(account);
        if (!coin::is_account_registered<CoinA>(account_addr)) {
            coin::register<CoinA>(account);
        };
        let caps = borrow_global<Caps<CoinA>>(@ArbitrageAddr);
        let coins = coin::mint(amount, &caps.mint_cap);
        coin::deposit(account_addr, coins);
    }

    public entry fun mint_coin_b(account: &signer, amount: u64) acquires Caps {
        let account_addr = signer::address_of(account);
        if (!coin::is_account_registered<CoinB>(account_addr)) {
            coin::register<CoinB>(account);
        };
        let caps = borrow_global<Caps<CoinB>>(@ArbitrageAddr);
        let coins = coin::mint(amount, &caps.mint_cap);
        coin::deposit(account_addr, coins);
    }
}
