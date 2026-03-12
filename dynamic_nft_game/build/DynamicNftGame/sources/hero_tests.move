#[test_only]
module GameAddr::hero_tests {
    use std::signer;
    use std::string;
    use aptos_framework::account;
    
    use GameAddr::hero_game;

    // 유저 계정 설정 헬퍼
    fun setup_user(user: &signer) {
        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
    }

    #[test(user = @0x123)]
    fun test_mint_and_dynamic_level_up(user: &signer) {
        setup_user(user);
        
        let user_addr = signer::address_of(user);

        // 1. 유저 계정에 영웅을 직접 발행(Mint)하여 저장
        hero_game::mint_hero(user, string::utf8(b"My Awesome Hero"));
        
        // 초기 스펙 확인: 레벨 1, 공격력 10
        assert!(hero_game::get_hero_level(user_addr) == 1, 0);
        assert!(hero_game::get_hero_attack_power(user_addr) == 10, 1);

        // 2. 사냥(hunt_monster) 1회 실행: 경험치 50 획득
        hero_game::hunt_monster(user);
        
        // 사냥 후 레벨 확인: 아직 레벨 업 조건(XP > 레벨 * 100) 도달 안함 (현재 50)
        assert!(hero_game::get_hero_level(user_addr) == 1, 2);
        assert!(hero_game::get_hero_attack_power(user_addr) == 10, 3);

        // 3. 다시 사냥! 경험치 추가로 50 획득 -> 총 100 (레벨 1*100 충족) -> 동적 속성 변화 발생 (레벨업)
        hero_game::hunt_monster(user);
        
        // 동적이게 속성이 변화했는지 검사
        // 레벨: 1 -> 2
        // 공격력: 10 -> 15 (+5)
        assert!(hero_game::get_hero_level(user_addr) == 2, 4);
        assert!(hero_game::get_hero_attack_power(user_addr) == 15, 5);
    }
}
