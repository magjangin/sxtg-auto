# 오토플레이(AutoPlay) 시스템 가이드

## 개요

오토플레이는 Sixtar Gate STARTRAIL의 리듬게임 플레이를 자동으로 수행하는 기능입니다. Harmony 패치를 사용하여 게임의 판정 시스템을 후킹하고, 현재 시간에 맞춰 자동으로 노트를 판정하도록 합니다.

## 작동 원리

### 1. 씬 감지 (Scene Detection)

```
MusicSelect 씬 → "play"/"rhythm"/"game" 포함 → AutoPlayEnabled = true
     ↓
  Play 씬 ← 자동으로 오토플레이 활성화
     ↓
SelectMusic 씬 → AutoPlayEnabled = false (자동 비활성화)
```

**구현 위치**: `Main.cs`
- `OnActiveSceneChanged()`: 씬 변경 감지
- `IsPlaySceneName()`: 플레이 씬 판별 (경우의 수 대응)
  - "play" 포함
  - "rhythm" 포함
  - "game" 포함

### 2. 시간 캡처 (Time Capture)

게임의 현재 재생 시간을 캡처하여 오토플레이에 사용합니다.

**구현 위치**: `AutoPlayPatch.cs` - `TimeCapturePatch` 내부 클래스

```csharp
[HarmonyPatch]
private static class TimeCapturePatch
{
    private static MethodBase TargetMethod()
    {
        // ManagerPlay.CheckGameFinished(float currentTime) 후킹
        var t = AccessTools.TypeByName("RhythmGame.Play.ManagerPlay") 
             ?? AccessTools.TypeByName("ManagerPlay");
        return AccessTools.Method(t, "CheckGameFinished", new[] { typeof(float) });
    }

    private static void Prefix(float __0)
    {
        Main.CurrentTimeSeconds = __0;  // 현재 시간 저장
    }
}
```

**특징**:
- `ManagerPlay.CheckGameFinished(float currentTime)`의 Prefix에서 시간 캡처
- 모든 게임 업데이트 프레임마다 현재 시간 갱신
- `Main.CurrentTimeSeconds`에 저장되어 오토플레이에서 참조

### 3. 오토플레이 판정 로직

**구현 위치**: `AutoPlayPatch.cs` - `RG_PS_Judgement_Update_Postfix()`

```
게임 업데이트 프레임
    ↓
RG_PS_Judgement.Update() 호출
    ↓
Postfix 실행
    ↓
AutoPlayEnabled == true?
    ↓ (Yes)
모든 레인 순회 (0 ~ numLanes-1)
    ↓
각 레인에서 AutoPlayJudge(currentTime, lane) 호출
    ↓
자동 판정 수행
```

### 4. 필드 캐싱 (Field Caching)

첫 번째 실행 시에만 리플렉션으로 메서드/필드를 찾고, 이후 캐시에서 재사용합니다.

**캐시 대상**:
```csharp
private static Action<RG_PS_Judgement, float, int> _autoPlayJudge;
private static FieldInfo _noteJudgeCursorField;
private static FieldInfo _numLanesField;
```

**캐싱 메서드**:
```csharp
private static void EnsureCaches()
{
    // 1. AutoPlayJudge 메서드 위임 생성
    if (_autoPlayJudge == null)
    {
        var m = AccessTools.Method(typeof(RG_PS_Judgement), 
            "AutoPlayJudge", 
            new[] { typeof(float), typeof(int) });
        if (m != null)
            _autoPlayJudge = AccessTools.MethodDelegate<Action<RG_PS_Judgement, float, int>>(m);
    }

    // 2. 필드 정보 캐싱
    if (_noteJudgeCursorField == null)
        _noteJudgeCursorField = AccessTools.Field(typeof(RG_PS_Judgement), "noteJudgeCursor");
    if (_numLanesField == null)
        _numLanesField = AccessTools.Field(typeof(RG_PS_Judgement), "numLanes");
}
```

**성능 최적화**:
- 캐시 미스: 1회만 리플렉션 수행 (프로그램 시작 시)
- 캐시 히트: 매 프레임 O(1) 조회
- 리플렉션 오버헤드 제거로 60FPS 유지

### 5. 오토플레이 결과 차단

오토플레이로 진행한 결과가 베스트 스코어, 풀콤보, 랭크 갱신, 서버 랭킹 제출에 반영되지 않도록 결과 씬의 저장 진입점만 차단합니다.

**구현 위치**: `SaveBestRankingBlockPatch.cs`

차단 대상은 두 개입니다.

- `RhythmGame.Result.ManagerResult.ComparePlayResultHighScore`
  - 베스트 점수, 풀콤보, 랭크 갱신, `SavePlayData` 호출 흐름 차단
- `RhythmGame.Result.ManagerResult.PostRequestPlayResult`
  - `LyrebirdServer.PostUserScore` 서버 랭킹 제출 흐름 차단

현재 구현은 플레이 씬에 진입하면 `Main.BlockSaveBestRanking`을 `true`로 설정하고, 위 두 메서드의 Prefix에서 `false`를 반환해 원본 실행을 막습니다.

## 핵심 메서드

### Main.cs

#### `OnInitializeMelon()`
- MelonLoader 초기화 진입점
- Harmony 패치 적용
- 씬 감지 이벤트 등록
- 초기 씬 상태 적용

#### `OnActiveSceneChanged(Scene prev, Scene next)`
- 씬 변경 감지 콜백
- `ApplyAutoPlayByScene()` 호출

#### `IsPlaySceneName(string sceneName)`
- 플레이 씬 판별 로직
- "play", "rhythm", "game" 포함 여부 확인
- 버전 호환성을 위해 부분 일치(Contains) 사용

#### `ApplyAutoPlayByScene(string sceneName)`
- 씬 이름에 따라 `AutoPlayEnabled` 설정
- 플레이 씬 진입 시 `BlockSaveBestRanking` 설정
- 씬 이탈 시 `CurrentTimeSeconds` 초기화
- 상태 변화만 로깅 (변화 없으면 로그 제외)

### AutoPlayPatch.cs

#### `RG_PS_Judgement_Update_Postfix(RG_PS_Judgement __instance)`
- Postfix: RG_PS_Judgement.Update() 이후 실행
- 모든 레인에 대해 오토플레이 판정 수행
- 예외 처리: 게임 플레이 중 도중 패치 오류로 인한 크래시 방지

#### `EnsureCaches()`
- 필드/메서드 캐싱 초기화
- 게으른 초기화(Lazy Initialization) 패턴 사용

#### `GetLaneCount(RG_PS_Judgement instance)`
- 게임의 레인(판정 채널) 개수 파악
- 우선순위:
  1. `noteJudgeCursor` 리스트 길이 (가장 신뢰성 높음)
  2. `numLanes` 필드 값 (범위 검증: 0 < n ≤ 10)
  3. 기본값 10 (최악의 경우)

### SaveBestRankingBlockPatch.cs

#### `TargetMethods()`
- 결과 반영과 서버 제출의 최상위 진입점만 후킹
- 현재 차단 대상:
  - `ComparePlayResultHighScore`
  - `PostRequestPlayResult`

#### `Prefix(MethodBase __originalMethod)`
- `Main.BlockSaveBestRanking == true`일 때 원본 메서드 실행 차단
- 차단된 메서드는 최초 1회 로그 출력
- `false` 반환으로 Harmony가 원본 메서드를 실행하지 않게 함

## 게임의 AutoPlayJudge 메서드

게임 자체에 구현된 `RG_PS_Judgement.AutoPlayJudge(float currentTime, int lane)` 메서드를 호출합니다.

**추정되는 동작**:
```
현재 시간(currentTime)과 lane에 기반하여
    ↓
해당 레인의 다음 노트 찾기 (noteJudgeCursor 사용)
    ↓
노트의 판정 타이밍(hitTiming)과 비교
    ↓
-50ms ~ +50ms (또는 게임별 범위) 내에 있으면
    ↓
자동 판정 수행 (JudgeAction 호출)
    ↓
Perfect 판정으로 처리
```

## 장점

1. **자동 업데이트**: 씬 변경 시 자동으로 ON/OFF
2. **성능**: 캐싱으로 리플렉션 오버헤드 최소화
3. **안정성**: 예외 처리로 게임 크래시 방지
4. **유연성**: 게임의 `AutoPlayJudge` 메서드 활용 (직접 구현 불필요)
5. **호환성**: 게임 버전 변화에 대응 가능한 문자열 기반 타입 탐색

## 주의사항

1. **씬 이름**: 게임 버전에 따라 씬 이름이 변할 수 있음
   - 대소문자 무관하게 처리
   - 부분 일치로 유연성 확보

2. **메서드 시그니처**: `AutoPlayJudge(float, int)` 메서드가 없으면 작동하지 않음
   - 게임 버전 호환성 문제 발생 가능

3. **타이밍 정확도**: 게임의 판정 범위에 따라 결정됨
   - 모드 제어 범위 외

4. **멀티스레드 안정성**: `CurrentTimeSeconds`는 메인 스레드에서만 접근
   - 다른 스레드에서 접근하면 경쟁 상태(Race Condition) 발생 가능

## 디버그 팁

### 오토플레이가 작동하지 않을 때

1. **로그 확인**:
   ```
   [씬] Play -> 오토플레이 ON
   ```
   씬 감지가 정상 작동하는지 확인

2. **메서드 존재 확인**: 게임에 `AutoPlayJudge` 메서드가 있는지 확인
   - 게임 버전에 따라 메서드명이 다를 수 있음

3. **타이밍 확인**: 게임 시간(`CurrentTimeSeconds`)이 정상으로 갱신되는지 확인
   - TimeCapturePatch의 TargetMethod가 올바른지 확인

4. **레인 개수**: `GetLaneCount()`의 반환값 확인
   - 게임의 실제 레인 개수와 일치하는지 확인

## 확장 가능성

### 오토플레이 난이도 조정
- `AutoPlayJudge` 호출 전에 시간 또는 판정 범위를 조정
- Great/Good/Miss 혼합 구현 가능

### 선택적 오토플레이
- 특정 레인만 오토플레이 활성화

### 성능 모니터링
- 오토플레이 활성화 시 FPS 모니터링
- 캐싱 효율성 측정 가능

## 참고 자료

- [Main.cs](../sxtg%20auto/Main.cs) - 씬 감지 및 초기화
- [AutoPlayPatch.cs](../sxtg%20auto/AutoPlayPatch.cs) - 오토플레이 구현
- [SaveBestRankingBlockPatch.cs](../sxtg%20auto/SaveBestRankingBlockPatch.cs) - 오토플레이 결과 저장/랭킹 차단
