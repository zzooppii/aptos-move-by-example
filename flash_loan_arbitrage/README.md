# 다이내믹 플래시론 차익거래 시뮬레이션 (Flash Loan Arbitrage Simulation)

## 프로젝트 개요
이 프로젝트는 **Aptos Move 언어**의 고유한 특징 중 하나인 `Hot Potato` 패턴을 활용하여 플래시론(Flash Loan) 대출과 이를 이용한 무위험 차익거래(Arbitrage)를 시뮬레이션하는 스마트 컨트랙트입니다. 면접 및 포트폴리오 목적으로 Move 언어의 보안성과 철학을 증명하기 위해 작성되었습니다.

## 핵심 구조

### 1. `coins.move` (가상 자산)
* Aptos 코어 프레임워크를 사용하여 테스트 목적의 가상 자산인 `CoinA`와 `CoinB`를 정의합니다.

### 2. `mock_dex.move` 및 `mock_dex_2.move` (가상 탈중앙화 거래소)
* 두 종류의 코인을 상호 교환할 수 있는 상수곱(x * y = k) 가격 결정 모델 기반의 가상 AMM(Automated Market Maker) 풀 두 개를 모방합니다.
* 시뮬레이션에서는 두 DEX 간의 초기 유동성 비율을 다르게 설정하여 가격 불균형 상황(차익거래 기회)을 조성합니다.

### 3. `flash_loan.move` (플래시론 대출 풀)
* 대출을 실행할 때 원금 및 수수료와 더불어 **영수증(Receipt)** 구조체를 반환합니다.
* 영수증은 `store`, `drop`, `copy` 능력이 없는 **Hot Potato 패턴**으로 작성되어, 트랜잭션이 끝나기 전 반드시 `repay_loan` 함수를 통해 소비(Destruct)되어야만 합니다. 이를 통해 컴파일러 및 런타임 단계에서 강력하게 롤백을 보장하고 상환을 강제합니다.

### 4. `arbitrage.move` (차익거래 실행 코어)
* 단일 트랜잭션 내에서 **대출 -> DEX 1 스왑 -> DEX 2 스왑 -> 대출 상환 -> 이익금 정산**의 사이클을 오케스트레이션합니다. 

### 5. `arbitrage_tests.move` (단위 테스트)
* **성공 시나리오 (`test_successful_arbitrage`)**: 두 DEX 간의 가격차를 이용해 충분한 수익을 창출하고 성공적으로 플래시론을 갚은 후 유저에게 수익이 남는지 검증합니다.
* **실패 및 롤백 시나리오 (`test_failed_arbitrage_reverts`)**: 과도한 금액을 대출받아 극단적인 슬리피지로 인해 수익이 나지 않는 상황을 시뮬레이션하며, 자산 부족으로 상환이 불가능해져 전체 트랜잭션이 완벽하게 초기화(`abort`)됨을 증명합니다.

---

## 빌드 및 테스트 실행 가이드

### 필수 환경 (macOS)
1. Homebrew를 이용한 Aptos CLI 설치
   ```bash
   brew install aptos
   ```

### 테스트 실행
프로젝트 루트 폴더 혹은 컨트랙트 폴더 내에서 다음 명령어를 실행하면 Move 내장 테스트 런타임을 통해 검증이 진행됩니다.

```bash
aptos move test
```

### 테스트 결과 예시
```text
Running Move unit tests
[ PASS    ] 0xcafe::arbitrage_tests::test_failed_arbitrage_reverts
[ PASS    ] 0xcafe::arbitrage_tests::test_successful_arbitrage
Test result: OK. Total tests: 2; passed: 2; failed: 0
{
  "Result": "Success"
}
```
