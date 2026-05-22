@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo.
echo ========================================
echo.
echo SXTG Auto Modding Build Script
echo.
echo ========================================
echo.

:: 프로젝트 설정
set "PROJECT_NAME=SxtgAuto"
set "PROJECT_DIR=sxtg auto"
set "SOLUTION_FILE=sxtg auto.sln"
set "GAME_PATH=H:\Sixtar Gate STARTRAIL custom mode"
set "SOURCE_ROOT=H:\source\repos\sxtg auto"

:: 빌드 경로
set "DLL_NAME=%PROJECT_NAME%.dll"
set "MODS_DIR=%GAME_PATH%\Mods"
set "SOURCE_DLL=%SOURCE_ROOT%\%PROJECT_DIR%\bin\Debug\%DLL_NAME%"
set "TARGET_DLL=%MODS_DIR%\%DLL_NAME%"

:: MSBuild 경로 찾기
set "MSBUILD_PATH="

if exist "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" (
    set "MSBUILD_PATH=C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe"
)
if "!MSBUILD_PATH!"=="" if exist "C:\Program Files\Microsoft Visual Studio\18\Professional\MSBuild\Current\Bin\MSBuild.exe" (
    set "MSBUILD_PATH=C:\Program Files\Microsoft Visual Studio\18\Professional\MSBuild\Current\Bin\MSBuild.exe"
)
if "!MSBUILD_PATH!"=="" if exist "C:\Program Files\Microsoft Visual Studio\18\Enterprise\MSBuild\Current\Bin\MSBuild.exe" (
    set "MSBUILD_PATH=C:\Program Files\Microsoft Visual Studio\18\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
)
if "!MSBUILD_PATH!"=="" if exist "C:\Program Files\Microsoft Visual Studio\2026\Community\MSBuild\Current\Bin\MSBuild.exe" (
    set "MSBUILD_PATH=C:\Program Files\Microsoft Visual Studio\2026\Community\MSBuild\Current\Bin\MSBuild.exe"
)
if "!MSBUILD_PATH!"=="" if exist "C:\Program Files\Microsoft Visual Studio\2026\Professional\MSBuild\Current\Bin\MSBuild.exe" (
    set "MSBUILD_PATH=C:\Program Files\Microsoft Visual Studio\2026\Professional\MSBuild\Current\Bin\MSBuild.exe"
)
if "!MSBUILD_PATH!"=="" if exist "C:\Program Files\Microsoft Visual Studio\2026\Enterprise\MSBuild\Current\Bin\MSBuild.exe" (
    set "MSBUILD_PATH=C:\Program Files\Microsoft Visual Studio\2026\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
)
if "!MSBUILD_PATH!"=="" if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" (
    set "MSBUILD_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
)
if "!MSBUILD_PATH!"=="" if exist "C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe" (
    set "MSBUILD_PATH=C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\MSBuild.exe"
)
if "!MSBUILD_PATH!"=="" if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe" (
    set "MSBUILD_PATH=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
)
if "!MSBUILD_PATH!"=="" if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe" (
    set "MSBUILD_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
)

if "!MSBUILD_PATH!"=="" (
    echo [오류] MSBuild를 찾을 수 없습니다.
    echo [오류] Visual Studio가 설치되어 있는지 확인하세요.
    pause
    exit /b 1
)

echo [정보] MSBuild 경로: !MSBUILD_PATH!
echo.

:: 스크립트 디렉토리 가져오기
set "SCRIPT_DIR=%~dp0"
set "SOLUTION_PATH=!SCRIPT_DIR!!SOLUTION_FILE!"

echo [정보] Debug 빌드 시작...
echo [정보] 게임 경로: !GAME_PATH!
echo.

:: NuGet 패키지 복원
echo [정보] NuGet 패키지 복원 중...
"!MSBUILD_PATH!" "!SOLUTION_PATH!" /p:Configuration=Debug /p:Platform="Any CPU" /p:GamePath="!GAME_PATH!" /t:Restore /v:minimal /nologo

:: 프로젝트 빌드
echo [정보] 프로젝트 빌드 중...
"!MSBUILD_PATH!" "!SOLUTION_PATH!" /p:Configuration=Debug /p:Platform="Any CPU" /p:GamePath="!GAME_PATH!" /t:Build /v:minimal /nologo

if errorlevel 1 (
    echo.
    echo ========================================
    echo [오류] 빌드 실패
    echo ========================================
    pause
    exit /b 1
)

echo.
echo ========================================
echo [성공] 빌드 완료
echo ========================================
echo.

:: DLL 파일 검증
if not exist "!SOURCE_DLL!" (
    echo [오류] DLL 파일을 찾을 수 없습니다: !SOURCE_DLL!
    pause
    exit /b 1
)

for %%F in ("!SOURCE_DLL!") do (
    set "FILE_SIZE=%%~zF"
    set "FILE_TIME=%%~tF"
)

echo [정보] 빌드된 DLL 파일: !SOURCE_DLL!
echo [정보] 파일 크기: !FILE_SIZE! bytes
echo [정보] 수정 시간: !FILE_TIME!
echo.

if !FILE_SIZE! LSS 1024 (
    echo [오류] DLL 파일 크기가 너무 작습니다: !FILE_SIZE! bytes
    pause
    exit /b 1
)

:: Mods 디렉토리로 복사
echo ========================================
echo [단계] Mods 디렉토리로 DLL 복사 중...
echo ========================================
echo.

if not exist "!GAME_PATH!" (
    echo [오류] 게임 디렉토리를 찾을 수 없습니다: !GAME_PATH!
    pause
    exit /b 1
)

if not exist "!MODS_DIR!" (
    echo [정보] Mods 디렉토리 생성 중...
    mkdir "!MODS_DIR!"
)

echo [정보] 복사 중: !SOURCE_DLL!
echo [정보]      대상: !TARGET_DLL!
echo.

copy /Y "!SOURCE_DLL!" "!TARGET_DLL!" >nul

if errorlevel 1 (
    echo [오류] 파일 복사 실패
    pause
    exit /b 1
)

:: 복사된 파일 검증
for %%F in ("!TARGET_DLL!") do set "COPIED_SIZE=%%~zF"

if not "!FILE_SIZE!"=="!COPIED_SIZE!" (
    echo [오류] 파일 크기가 일치하지 않습니다!
    echo [오류] 원본: !FILE_SIZE! bytes
    echo [오류] 복사본: !COPIED_SIZE! bytes
    pause
    exit /b 1
)

echo ========================================
echo [성공] DLL 복사 완료
echo ========================================
echo.
echo [정보]  원본: !SOURCE_DLL!
echo [정보]  대상: !TARGET_DLL!
echo [정보]  파일 크기: !COPIED_SIZE! bytes
echo.
echo [조작법]
echo   F1 키: 오토플레이 ON/OFF
echo.

pause

