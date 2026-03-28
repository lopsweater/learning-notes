@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================
:: ④ SVN 提交（从主 Worktree）
:: 用法: push-svn.bat [提交信息]
:: ============================================

set REPOS_DIR=C:\repos
set WORK_DIR=C:\work
set COMMIT_MSG=%~1

:: 获取项目名称
for /f "tokens=*" %%i in ('dir /b /ad "%REPOS_DIR%\*.git" 2^>nul') do (
    set GIT_DIR=%%i
    goto :found_git
)

echo 错误: 未找到 Git 仓库
exit /b 1

:found_git
set PROJECT_NAME=%GIT_DIR:.git=%
set SVN_DIR=%WORK_DIR%\%PROJECT_NAME%-svn

if not exist "%SVN_DIR%\.svn" (
    echo 错误: 未找到 SVN 工作副本
    echo   %SVN_DIR%
    exit /b 1
)

echo.
echo ══════════════════════════════════════════════════════════
echo   ④ SVN 提交
echo ══════════════════════════════════════════════════════════
echo.

cd /d "%SVN_DIR%"

echo [检查 1/3] Git 状态...
git status -s
echo.

echo [检查 2/3] SVN 状态...
svn status
echo.

:: 检查是否有 SVN 变更
svn status | findstr /R /C:"^[AMDR]" >nul
if errorlevel 1 (
    echo ✓ 无 SVN 变更需要提交
    goto :end
)

:: 如果没有提供提交信息，询问
if "%COMMIT_MSG%"=="" (
    echo [输入 3/3] 请输入 SVN 提交信息:
    set /p COMMIT_MSG="> "
)

if "!COMMIT_MSG!"=="" (
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set DATETIME=%%I
    set COMMIT_MSG=Update !DATETIME:~0,8!
)

echo.
echo 提交信息: %COMMIT_MSG%
echo.
set /p CONFIRM="确认提交? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo 已取消
    exit /b 0
)

echo.
echo [提交] svn commit...
svn commit -m "%COMMIT_MSG%"

if errorlevel 1 (
    echo.
    echo ✗ SVN 提交失败
    pause
    exit /b 1
)

echo.
echo ✓ SVN 提交成功

:: 记录到 Git
echo.
echo [记录] 提交到 Git...
git add -A
git commit -m "已提交 SVN: %COMMIT_MSG%" 2>nul

:end
echo.
echo ══════════════════════════════════════════════════════════
echo   ✓ 完成
echo ══════════════════════════════════════════════════════════
echo.

pause
