# ScoreBlacker

Sixtar Gate STARTRAIL 게임용 MelonLoader 모드로, 스코어 시스템을 분석하고 조작하는 도구입니다.

## 개요

이 모드는 Harmony 패치를 사용하여 게임의 스코어 계산 시스템을 후킹하고, 점수를 제한된 증가량(0.01씩)으로 조작하며, 모든 판정을 Perfect로 강제 변경하는 기능을 제공합니다.

## 주요 기능

### 1. 스코어 조작
- **제한된 점수 증가**: 원본 점수 증가량을 0.01씩만 증가하도록 제한
- **판정 강제 변경**: 모든 판정(Great, Good, Miss 등)을 Perfect로 자동 변경
- **점수 필드 직접 수정**: JudgeScore, Score 프로퍼티 및 관련 필드를 조작된 값으로 덮어쓰기

### 2. 씬 분석
- **플레이 씬 분석**: "Play" 씬 로드 시 Score 관련 오브젝트 자동 검색 및 출력
- **타입 분석**: Assembly-CSharp.dll에서 스코어 관련 타입, 메서드, 필드 자동 검색
- **판정 시스템 분석**: RG_PS_Judgement 타입의 상세 분석 (필드, 메서드, 판정 타입 enum)

### 3. 키보드 단축키
- **ESC 한 번**: `RG_PS_Pause.Show()`와 `Start()` 메서드 강제 호출
- **ESC 두 번** (0.5초 내): `RG_PS_Pause.Close()` 메서드 강제 호출
- **1번 키**: `Show()`와 `Start()` 메서드 강제 호출

## 프로젝트 구조

### 핵심 클래스

#### `SceneDetector.cs` (메인 모드)
- MelonLoader 모드 진입점
- Harmony 패치 적용 및 관리
- 키보드 입력 처리 (ESC, 1번 키)
- 씬 로드 이벤트 처리
- 스코어 조작 설정 관리 (`ScoreMultiplier`, `AdditionalScore`, `DebugMode`)

#### `ScorePatches.cs` (스코어 패치)
- `AddStarlightScore`: 스타라이트 점수 추가 메서드 후킹
- `CalculateJudgeScore`: 판정 점수 계산 메서드 후킹
- `OnScoreUpdated`: 점수 업데이트 메서드 후킹 (핵심 로직)
  - 판정을 Perfect로 강제 변경
  - 점수를 0.01씩만 증가하도록 제한
  - JudgeScore 필드 직접 수정
- `Score` / `JudgeScore` 프로퍼티 getter 후킹
- `AddCombo`: 콤보 추가 메서드 후킹

#### `JudgePatches.cs` (판정 패치)
- `JudgeAction`: 판정 액션 메서드 후킹
  - Postfix에서 모든 판정을 Perfect로 변경
  - 판정 정보 로깅
- `JudgeDivergence`: 판정 분기 메서드 후킹
- `TryJudgeShortNote`: 짧은 노트 판정 메서드 후킹

#### `WidgetPatches.cs` (UI 위젯 패치)
- `PlayWidget.OnGetScore`: UI에 점수 표시 시 후킹
- `RG_Scoreboard.InterpolateToScore`: 스코어보드 점수 보간 후킹
- `HighscoreMeter.OnGetScore`: 하이스코어 미터 점수 후킹
- 범용 후킹 메서드:
  - `GenericIntPrefix`: int 파라미터 1개 메서드 후킹
  - `GenericFloatPrefix`: float 파라미터 1개 메서드 후킹
  - `GenericInt2Prefix`: int 파라미터 2개 메서드 후킹
  - `GenericFloat2Prefix`: float 파라미터 2개 메서드 후킹

### 분석 유틸리티 클래스

#### `SceneAnalyzer.cs`
- 플레이 씬에서 "Score"가 포함된 오브젝트 재귀적 검색
- 오브젝트 경로, 컴포넌트 정보 출력
- 다른 Analyzer들을 호출하여 상세 분석 수행

#### `JudgementAnalyzer.cs`
- `RG_PS_Judgement` 타입 상세 분석:
  - 모든 필드 출력
  - 스코어 관련 메서드 상세 분석
  - 판정 관련 메서드 상세 분석
  - JudgeCounter 타입 분석
  - 판정 타입 enum 분석 (Perfect, Great, Good 등)

#### `ScoreTypeAnalyzer.cs`
- "Score"가 포함된 모든 타입 검색
- 스코어 관리 관련 타입 검색 (Manager, Judgement 등)
- 타입의 메서드, 필드, 프로퍼티 출력

#### `PauseButtonsAnalyzer.cs`
- `RhythmGame.Play.PauseButtons` 타입 분석
- Pause UI 관련 타입 검색 및 분석

## 작동 원리

### 1. 초기화 과정
1. `SceneDetector.OnInitializeMelon()`에서 Harmony 패치 적용
2. `ApplyScorePatches()`에서 스코어 관련 메서드 자동 검색 및 후킹
3. 범용 스코어 메서드 검색 (`ApplyGenericScorePatches`)

### 2. 스코어 조작 로직
1. **OnScoreUpdated Prefix**:
   - JudgeCounter의 judgeCount 배열에서 Perfect가 아닌 판정을 모두 0으로 설정
   - Perfect 인덱스(0)에 모든 판정 추가
   - JudgeScore 필드에서 원본 점수 읽기
   - 원본 점수가 0.1 이상 증가했으면 `LastManipulatedScore`를 0.01 증가
   - 파라미터 `__0`을 조작된 값으로 대체
   - JudgeScore 필드 직접 수정

2. **OnScoreUpdated Postfix**:
   - JudgeScore 필드가 원본 값으로 되돌아갔는지 확인
   - 조작된 값으로 다시 수정
   - 다른 Score 관련 필드도 수정

3. **프로퍼티 Getter 후킹**:
   - `Score` / `JudgeScore` 프로퍼티를 읽을 때 조작된 값 반환

### 3. 판정 강제 변경
- `JudgeAction` Postfix와 `OnScoreUpdated` Prefix에서:
  - JudgeCounter의 `judgeCount` 배열을 읽음
  - 인덱스 1 이상(Perfect가 아닌 판정)의 값을 모두 0으로 설정
  - 인덱스 0(Perfect)에 모든 판정 추가

### 4. 범용 메서드 후킹
- Assembly-CSharp.dll의 모든 타입을 검색
- 메서드 이름에 "Score"가 포함되거나 파라미터 이름에 "score"가 포함된 메서드 자동 후킹
- 파라미터 타입(int/float)에 따라 적절한 범용 후킹 메서드 선택

## 설정

### `SceneDetector` 정적 필드
- `ScoreMultiplier` (float): 스코어 배율 (기본값: 1.0f)
- `AdditionalScore` (float): 추가 스코어 (기본값: 0.0f)
- `DebugMode` (bool): 디버그 모드 활성화 여부 (기본값: false)
- `LastManipulatedScore` (float): 조작된 점수 추적 (0.01씩 증가)

## 빌드

### 요구사항
- Visual Studio 2022 (MSBuild)
- .NET Framework 4.7.2
- MelonLoader (게임 설치 폴더에 설치 필요)
- Harmony (MelonLoader와 함께 제공)

### 빌드 방법
1. **일반 빌드**: `build.bat` 실행
2. **클린 빌드**: `clean_build.bat` 실행

빌드 출력: `scoreblacker\bin\Debug\scoreblacker.dll`

### 설치
1. 빌드된 `scoreblacker.dll`을 게임의 `Mods` 폴더에 복사
2. 게임 실행 시 MelonLoader가 자동으로 로드

## 후킹된 메서드 목록

### RG_PS_Judgement 클래스
- `AddStarlightScore(float)`
- `CalculateJudgeScore(float)` (private)
- `OnScoreUpdated(int)` (private)
- `AddCombo(int)` (private)
- `JudgeAction()`
- `JudgeDivergence()`
- `TryJudgeShortNote()`
- `Score` 프로퍼티 getter
- `JudgeScore` 프로퍼티 getter

### UI 위젯 클래스
- `PlayWidget.OnGetScore(int)`
- `PlayWidget.OnGetScore(int, int)`
- `RG_Scoreboard.InterpolateToScore(int)`
- `HighscoreMeter.OnGetScore(int)`

### 범용 후킹
- Assembly-CSharp.dll 내의 모든 스코어 관련 메서드 자동 검색 및 후킹

## 로깅

### 디버그 모드 (`DebugMode = true`)
- 모든 후킹된 메서드 호출 로그
- 점수 변경 내역
- 판정 정보
- 필드 수정 내역

### 조용한 모드 (`DebugMode = false`, 기본값)
- 핵심 동작만 로그 출력
- 스팸 방지를 위한 최소한의 로그

## 로컬모드

로컬모드는 온라인 기능 없이 로컬 환경에서 게임을 플레이하고 테스트하기 위한 모드입니다.

### 특징
- **판정 자동화**: 모든 노트를 Perfect로 자동 판정
- **스코어 안정화**: 점수 증가를 0.01씩 제한하여 일관된 결과 제공
- **오토플레이**: 자동 판정 시스템을 통한 완전 자동 플레이
- **씬 자동 감지**: Play 씬에서 자동으로 기능 활성화
- **결과 차단**: 오토플레이 결과가 베스트 점수와 서버 랭킹에 반영되지 않도록 결과 저장 진입점 차단

### 작동 방식
1. 게임이 Play 씬으로 로드되면 자동으로 오토플레이 활성화
2. 매 프레임 현재 게임 시간을 캡처
3. 각 레인의 노트에 대해 정확한 타이밍에 자동 판정
4. 모든 판정을 Perfect로 강제 변환
5. 결과 씬에서 `ComparePlayResultHighScore`, `PostRequestPlayResult`를 차단해 베스트/랭킹 반영 방지
6. 게임 씬에서 벗어나면 자동으로 비활성화

### 활용 사례
1. 커스텀 차트 개발 및 검증
2. 게임 시스템 분석
3. 모드 기능 테스트
4. 자동 플레이 영상 및 데모 생성

## 확장 문서

### 오토플레이 상세 가이드
- [AUTOPLAY_GUIDE.md](./AUTOPLAY_GUIDE.md) - 오토플레이 시스템의 작동 원리, 구현 방식, 디버그 팁
  - 씬 감지 메커니즘
  - 시간 캡처 및 동기화
  - 필드 캐싱 및 성능 최적화
  - 게임의 AutoPlayJudge 메서드 활용
  - 오토플레이 결과 저장/랭킹 차단
  - 디버그 및 확장 가능성

## 주의사항

1. **게임 버전 호환성**: 게임 업데이트 시 Assembly-CSharp.dll의 타입 구조가 변경될 수 있음
2. **온라인 기능**: 현재 오토플레이 결과는 결과 씬의 저장/랭킹 제출 진입점에서 차단함
3. **디버그 모드**: 활성화 시 대량의 로그가 출력되어 성능에 영향을 줄 수 있음

## 라이선스

이 프로젝트는 교육 및 연구 목적으로 제작되었습니다.

