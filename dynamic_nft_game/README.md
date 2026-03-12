# 동적 NFT 및 온체인 성장 게임 시뮬레이션 (Dynamic NFT Game Simulation)

## 프로젝트 개요
이 프로젝트는 **Aptos Move 언어**의 강력한 자산 모델인 **리소스(Resource)**를 활용하여, 단순히 이미지를 증명하는 것을 넘어 게임의 진행에 따라 능력치(레벨, 공격력 등)가 실시간으로 변화하는 **완전한 100% 온체인 동적 NFT(Dynamic NFT)** 게임 로직을 시뮬레이션합니다. 

이 프로젝트는 기존 Solidity 기반의 NFT 생태계가 가지는 중앙화된 장부(Mapping) 의존성을 탈피하고, Move 언어만이 제안하는 진정한 형태의 디지털 자산(내 지갑 안에 물리적으로 존재하는 데이터)을 구현하고 증명하는 것을 목적으로 합니다.

## 핵심 구조

### 1. `hero_game.move` (동적 NFT 온체인 로직)
*   **영웅 리소스(`Hero`)**: `key` 어빌리티만 부여하여 오직 유저 계정(Account) 하위에만 저장될 수 있는 고유 자산 구조체를 정의합니다. 복사(Copy)되거나 삭제(Drop)되지 않으므로 해킹 및 버그로부터 안전합니다.
*   **영웅 발행(`mint_hero`)**: Solidity의 `balances[msg.sender] += 1`과 같은 거대 장부 기록 방식이 아닌, `move_to` 함수를 통해 생성된 영웅 리소스를 **유저의 계정 주소 하위로 영구적으로 이동(삽입)**시킵니다.
*   **사냥과 레벨업 로직(`hunt_monster`)**: 오프체인 서버에 의존하지 않습니다. 유저가 이 함수를 호출할 때마다 블록체인 상의 유저 계정에 저장된 `Hero`의 상태를 런타임에 쓰기 권한으로 가져와(`borrow_global_mut`) 경험치를 올려줍니다.
*   **실시간 온체인 진화**: 경험치가 특정 임계치(예: 레벨 * 100)를 넘으면 추가 트랜잭션 수수료 없이, 사냥 트랜잭션 내부에서 즉시 공격력과 레벨이 상승(진화)하는 다이내믹 NFT 메커니즘을 완성했습니다.

### 2. `hero_tests.move` (단위 테스트 및 시나리오 검증)
*   **`test_mint_and_dynamic_level_up`**: 유저가 영웅을 성공적으로 발행(Minting)받은 직후의 속성과, 사냥(`hunt_monster`)을 여러 번 거치면서 경험치가 쌓여 레벨과 공격력이 목표한 대로 상승하는지 검증합니다.
*   아무런 외부 스크립트 도구 없이, 오직 Move 내장 테스트 런타임을 통해 동적 변화가 완벽하게 추적되고 성공하는 것을 증명했습니다.

---

## 빌드 및 테스트 실행 가이드

### 필수 환경 (macOS)
1.  Homebrew를 이용한 Aptos CLI 사전 설치
    ```bash
    brew install aptos
    ```

### 테스트 실행
Aptos CLI가 설치된 터미널에서 `dynamic_nft_game` 프로젝트 폴더로 이동한 뒤, 아래 명령어를 실행하여 동적 속성 변화가 완벽히 적용되는지 확인합니다.

```bash
aptos move test
```

### 테스트 결과 예시
```text
Running Move unit tests
[ PASS    ] 0xcafe::hero_tests::test_mint_and_dynamic_level_up
Test result: OK. Total tests: 1; passed: 1; failed: 0
{
  "Result": "Success"
}
```
