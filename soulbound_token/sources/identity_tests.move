#[test_only]
module 0xcafe::identity_tests {
    use std::signer;
    use std::string;
    use 0xcafe::identity;

    #[test(user = @0x123)]
    fun test_issue_id(user: &signer) {
        let user_addr = signer::address_of(user);

        // 유저에게 신분증 발급!
        identity::issue_id(user, string::utf8(b"Harvey"), 28, string::utf8(b"South Korea"));

        // 발급이 완료되었는지 확인 (내 계정에 존재하는가?)
        let name = identity::get_name(user_addr);
        assert!(name == string::utf8(b"Harvey"), 1);

        // 💡 참고: 아래 코드를 실수로 작성하면 컴파일 에러가 터집니다!
        // Move 언어의 컴파일러가 "drop 능력이 없는 신분증을 왜 버리냐"고 화냅니다.
        // let card = ...가져오는 코드... ;
        // card; 
        
        // 또한, `transfer` 같은 전송 함수를 만들려 해도
        // IdentityCard 구조체에 `store` 능력이 없어서 파라미터로 넘길 수도 없습니다.
    }

    #[test(user = @0x123)]
    #[expected_failure(abort_code = 1, location = 0xcafe::identity)]
    fun test_reissue_fails(user: &signer) {
        // 이미 신분증이 있는 유저가 또 발급을 받으려 하면 컨트랙트가 거부합니다. -> EALREADY_HAS_ID 에러
        identity::issue_id(user, string::utf8(b"Alice"), 25, string::utf8(b"US"));
        
        // 여기서 에러 1번(EALREADY_HAS_ID)이 터지면서 롤백되어야 테스트 통과!
        identity::issue_id(user, string::utf8(b"Alice2"), 26, string::utf8(b"US")); 
    }
}
