# SXTG Auto

`SXTG Auto`는 **Sixtar Gate STARTRAIL**에서 사용하는 MelonLoader 오토플레이 모드입니다.
플레이 씬을 감지하면 게임의 판정 흐름에 Harmony 패치를 적용해 각 레인의 노트를 자동으로 판정합니다.

## 주요 기능

- 플레이 씬에서 오토플레이 자동 활성화
- 게임의 현재 재생 시간을 기준으로 각 레인의 `AutoPlayJudge` 호출
- 플레이 씬을 벗어나면 오토플레이 자동 비활성화
- 오토플레이 결과가 베스트 스코어와 서버 랭킹 제출에 반영되지 않도록 결과 저장 진입점 차단

## 요구 사항

- Sixtar Gate STARTRAIL
- MelonLoader
- Visual Studio 또는 MSBuild
- .NET Framework 4.7.2

## 빌드

1. `sxtg auto/sxtg auto.csproj`의 `GamePath`를 본인 게임 설치 경로에 맞게 수정합니다.
2. 저장소 루트의 `build.bat`를 실행합니다.
3. 빌드가 끝나면 `SxtgAuto.dll`이 게임의 `Mods` 폴더로 복사됩니다.

`build.bat`와 `install.bat`에도 게임 경로가 들어 있으므로 환경에 맞게 확인해 주세요.

## 설치

빌드된 `SxtgAuto.dll`을 게임 설치 폴더의 `Mods` 폴더에 넣고 게임을 실행합니다.
`build.bat`를 사용하면 빌드 후 복사까지 함께 진행합니다.

## 동작 방식

1. 모드가 초기화되면 Harmony 패치를 등록합니다.
2. 씬 이름에 `play`, `rhythm`, `game`이 포함되면 오토플레이를 활성화합니다.
3. 플레이 중 현재 시간을 캡처하고 각 레인에 게임의 자동 판정 메서드를 호출합니다.
4. 오토플레이로 진행한 결과는 베스트 점수 비교와 서버 결과 제출 진입점에서 차단합니다.

## 문서

- [오토플레이 구현 가이드](./%EC%98%A4%ED%86%A0%20%EC%A1%B0%EC%9E%91%20%EB%AA%A8%EB%93%9C/AUTOPLAY_GUIDE.md)

## 주의 사항

- 게임 업데이트로 내부 타입이나 메서드 이름이 바뀌면 패치가 동작하지 않을 수 있습니다.
- 이 프로젝트는 게임 모드 개발과 오토플레이 동작 검증 용도로 작성되었습니다.
