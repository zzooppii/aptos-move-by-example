# Aptos Move By Example

이 저장소는 **Aptos Move 언어**의 핵심적인 개념과 보안 패턴을 실전적인 예제와 시뮬레이션을 통해 보여주는 프로젝트 모음입니다. Solidity 등 기존 스마트 컨트랙트 언어와 차별화되는 Move 언어만의 강력한 **리소스 모델(Resource Model)**과 **핫 포테이토(Hot Potato) 패턴**을 학습하고 증명하는 데 목적이 있습니다.

## 📂 프로젝트 구성

이 저장소에는 두 가지 주요 온체인 시뮬레이션 프로젝트가 포함되어 있습니다.

### 1. [Dynamic NFT Game](./dynamic_nft_game)
단순한 메타데이터 변경을 넘어 물리적인 실체(리소스)로 존재하는 **100% 온체인 다이내믹 NFT** 시뮬레이션입니다.
* **핵심 학습 개념:** 리소스(Resource), `key` 어빌리티, 전역 저장소 제어(`move_to`, `borrow_global_mut`)
* **주요 기능:** 영웅(고유 NFT 자산)을 유저 지갑에 직접 발급하고, 사냥을 통해 실시간으로 체인 위에서 경험치와 레벨, 능력치를 변화시키는 로직 구현. (중앙화된 장부 매핑 방식 탈피)

### 2. [Flash Loan Arbitrage](./flash_loan_arbitrage)
유동성 풀 간의 가격 불균형을 이용한 **무위험 플래시론 차익거래(Arbitrage)** 시뮬레이션입니다.
* **핵심 학습 개념:** 핫 포테이토 패턴(Hot Potato Pattern), `abort` 롤백 보장 메커니즘
* **주요 기능:** 플래시론 대출, 두 개의 가상 DEX(상수곱 AMM)를 통한 교환, 플래시론 상환을 단일 트랜잭션 내에서 처리하며, 상환되지 않거나 수익이 나지 않을 경우 런타임 단계에서 완벽하게 트랜잭션을 롤백시킴.

---

## 🚀 시작하기

### 사전 요구 사항 (Requirements)
Aptos 스마트 컨트랙트를 빌드하고 테스트하기 위해 CLI 환경이 필요합니다. (macOS 기준)

```bash
brew install aptos
```

### 테스트 실행 방법
각 프로젝트 폴더로 이동하여 내장된 Move 테스트 환경을 통해 시나리오를 검증할 수 있습니다.

#### Dynamic NFT Game 테스트
```bash
cd dynamic_nft_game
aptos move test
```

#### Flash Loan Arbitrage 테스트
```bash
cd flash_loan_arbitrage
aptos move test
```

---

*본 프로젝트는 Aptos Move 언어의 아키텍처와 컨트랙트 보안성을 탐구하기 위해 작성되었습니다.*
