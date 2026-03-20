module 0xcafe::business_card {
    use std::string::String;

    /// 📄 [비교 목적 로직] 복사와 삭제가 자유로운 일반 데이터 (명함)
    /// `store, copy, drop` 능력이 모두 존재합니다.
    /// 누구나 마음대로 복사해서 뿌릴 수 있고, 볼일이 끝나면 무단으로 버릴(파기할) 수 있습니다.
    struct BusinessCard has key, store, copy, drop {
        name: String,
        company: String,
    }

    /// [명함 발급] 누구나 제약 없이 명함을 생성하고 돌려받을 수 있습니다.
    public fun create_business_card(name: String, company: String): BusinessCard {
        BusinessCard {
            name,
            company,
        }
    }

    /// [명함 복사와 파기 시뮬레이션]
    /// 파라미터로 명함을 '값(value)'으로 받아옵니다. (소유권 이전)
    public fun copy_and_drop_card(card: BusinessCard): BusinessCard {
        // `copy` 능력이 있으므로 붕어빵처럼 똑같은 명함을 하나 더 찍어냅니다.
        let new_card = copy card;

        // 파라미터로 들어왔던 원본 `card`는 여기서 아무 데도 안 쓰고 방치되지만,
        // `drop` 능력이 있으므로 컴파일 에러 없이 쓰레기통으로 부드럽게 사라집니다!
        
        // 새로 복사한 명함을 반환합니다.
        new_card
    }
}
