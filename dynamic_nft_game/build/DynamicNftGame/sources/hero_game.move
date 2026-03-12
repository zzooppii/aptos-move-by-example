module GameAddr::hero_game {
    use std::string::String;
    use std::signer;

    /// 에러 코드
    const EALREADY_HAS_HERO: u64 = 1;
    const EHERO_DOES_NOT_EXIST: u64 = 2;
    const ENOT_ENOUGH_ENERGY: u64 = 3;

    /// 🔥 [Move의 핵심] '영웅' 구조체 리소스입니다.
    /// `key` 어빌리티가 있으므로 계정 직하위에 저장됩니다.
    /// `copy`가 없으므로 무한 복제 불가, `drop`이 없으므로 임의 삭제 불가능한 완벽한 고유 자산(NFT)입니다.
    struct Hero has key {
        name: String,
        level: u64,
        experience: u64,
        hp: u64,
        attack_power: u64,
        energy: u64,
    }

    /// [1. 영웅 생성(Mint)] 영웅을 생성하여 유저의 '지갑(계정)' 안에 직접 넣어줍니다.
    /// Solidity였다면 `balances[msg.sender] = 1`, `owners[1] = msg.sender` 형식으로 장부에 기록하지만,
    /// Move에서는 리소스 구조체를 만들어 지갑으로 실제로 전송(`move_to`)합니다.
    public entry fun mint_hero(user: &signer, name: String) {
        let user_addr = signer::address_of(user);
        
        // 한 계정당 하나의 영웅만 가질 수 있도록 제한 (장부 조회가 아니라 내 계정에 있는지 조회)
        assert!(!exists<Hero>(user_addr), EALREADY_HAS_HERO);

        let new_hero = Hero {
            name,
            level: 1,
            experience: 0,
            hp: 100,
            attack_power: 10,
            energy: 50, // 행동력 부여
        };

        // 유저의 계정 저장소 시스템에 영웅 구조체를 영구적으로 삽입 (Minting)
        move_to(user, new_hero);
    }

    /// [2. 동적 게임 로직(Dynamic NFT)] 몬스터 사냥 함수
    /// 영웅의 정보를 실시간으로 수정하여 성장하는 동적 자산(Dynamic Asset)을 만듭니다.
    public entry fun hunt_monster(user: &signer) acquires Hero {
        let user_addr = signer::address_of(user);
        assert!(exists<Hero>(user_addr), EHERO_DOES_NOT_EXIST);

        // 내 지갑에서 영웅 리소스의 쓰기 권한(Mutable Reference)을 가져옵니다.
        let hero = borrow_global_mut<Hero>(user_addr);
        
        // 에너지 소모 검사
        assert!(hero.energy >= 10, ENOT_ENOUGH_ENERGY);
        hero.energy = hero.energy - 10;
        
        // 사냥 성공 (경험치 50 획득)
        hero.experience = hero.experience + 50;

        // [3. 실시간 레벨업 검증] - 경험치가 레벨당 100을 넘으면 실시간으로 능력치 상승
        if (hero.experience >= hero.level * 100) {
            hero.level = hero.level + 1;
            hero.attack_power = hero.attack_power + 5; // 공격력 +5
            hero.hp = hero.hp + 20;                    // 체력 +20
        }
    }

    /// (헬퍼 함수) 영웅의 현재 공격력을 조회합니다.
    public fun get_hero_attack_power(user_addr: address): u64 acquires Hero {
        borrow_global<Hero>(user_addr).attack_power
    }

    /// (헬퍼 함수) 영웅의 레벨을 조회합니다.
    public fun get_hero_level(user_addr: address): u64 acquires Hero {
        borrow_global<Hero>(user_addr).level
    }
}
