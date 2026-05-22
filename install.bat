@echo off
chcp 65001 >nul
echo ========================================
echo   SXTG Auto 모드 설치
echo ========================================
echo.

:: 게임 경로 설정 (본인 환경에 맞게 수정하세요)
set GAME_PATH=H:\Sixtar Gate STARTRAIL custom mode

:: 빌드된 DLL 확인
if not exist "sxtg auto\bin\Debug\SxtgAuto.dll" (
    echo [오류] 빌드된 DLL을 찾을 수 없습니다!
    echo 먼저 build.bat를 실행하세요.
    pause
    exit /b 1
)

:: Mods 폴더 확인
if not exist "%GAME_PATH%\Mods" (
    echo [오류] 게임 Mods 폴더를 찾을 수 없습니다!
    echo GAME_PATH 변수를 수정하세요.
    echo 현재 경로: %GAME_PATH%
    pause
    exit /b 1
)

:: DLL 복사
copy /Y "sxtg auto\bin\Debug\SxtgAuto.dll" "%GAME_PATH%\Mods\"

if %ERRORLEVEL% neq 0 (
    echo [오류] 파일 복사 실패!
    pause
    exit /b 1
)

echo.
echo ========================================
echo   설치 완료!
echo ========================================
echo.
echo SxtgAuto.dll이 Mods 폴더에 복사되었습니다.
echo 게임을 실행하면 모드가 자동으로 로드됩니다.
echo.
echo [조작법]
echo   F1 키: 오토플레이 ON/OFF
echo.
pause

