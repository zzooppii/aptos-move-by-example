module 0xcafe::identity {
    use std::string::String;
    use std::signer;

    /// 이미 신분증을 소유하고 있을 때 발생하는 에러
    const EALREADY_HAS_ID: u64 = 1;
    
    /// 신분증이 존재하지 않을 때 발생하는 에러
    const EHAS_NO_ID: u64 = 2;

    /// 🔥 [핵심 로직] 완벽한 귀속 객체 (Soulbound Token)
    /// `store` 능력이 없으므로 이 구조체는 지갑 외부로 전송되거나 다른 스마트 컨트랙트에 보관될 수 없습니다. (양도 불가)
    /// `copy` 능력이 없으므로 위조(복제)할 수 없습니다.
    /// `drop` 능력이 없으므로 내 마음대로 파기하거나 버릴 수 없습니다.
    /// 오직 `key` 능력만 있어서 생성 즉시 내 계정 하위에 '영구적으로 박제'됩니다.
    struct IdentityCard has key {
        name: String,
        age: u8,
        nationality: String,
    }

    /// [1. 신분증 발급] 
    /// 정부(또는 권한자)가 유저에게 신분증을 1회 발급해 줍니다.
    public entry fun issue_id(user: &signer, name: String, age: u8, nationality: String) {
        let user_addr = signer::address_of(user);
        
        // 1인당 1개의 신분증만 발급 가능하도록 검증 (내 지갑에 있는지 확인)
        assert!(!exists<IdentityCard>(user_addr), EALREADY_HAS_ID);

        let id_card = IdentityCard {
            name,
            age,
            nationality,
        };

        // 내 지갑(계정)에 영구적으로 귀속시킴
        // 이때 이후로는 코드로도 이 카드를 빼낼 방도가 없습니다 (store, drop 부재)
        move_to(user, id_card);
    }

    /// [2. 정보 조회] 내 신분증의 이름을 조회합니다.
    public fun get_name(user_addr: address): String acquires IdentityCard {
        assert!(exists<IdentityCard>(user_addr), EHAS_NO_ID);
        borrow_global<IdentityCard>(user_addr).name
    }
}
