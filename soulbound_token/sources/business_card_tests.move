#[test_only]
module 0xcafe::business_card_tests {
    use std::string;
    use 0xcafe::business_card;

    #[test]
    fun test_business_card_abilities() {
        // [비교 테스트] 명함 발급
        let card1 = business_card::create_business_card(
            string::utf8(b"Harvey"), 
            string::utf8(b"Awesome Startup")
        );

        // [복사 테스트 (`copy` 능력)] 똑같은 명함을 생성!
        let _card2 = business_card::copy_and_drop_card(card1);

        // 함수가 종료되는 시점입니다.
        // 현재 스코프에 _card2가 남아있지만, BusinessCard 구조체는 `drop` 능력이 있으므로 
        // 제가 직접 파기(Destruct, unpack)해 주지 않아도, 컴파일러가 조용히 메모리에서 삭제해 줍니다.
        // 에러 없이 완벽하게 통과합니다!
    }
}
