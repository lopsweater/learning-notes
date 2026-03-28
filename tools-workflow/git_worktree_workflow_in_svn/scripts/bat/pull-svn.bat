@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================
:: ① SVN 更新 + Git 同步
:: 用法: pull-svn.bat
:: ============================================

set REPOS_DIR=C:\repos
set WORK_DIR=C:\work

:: 获取项目名称
for /f "tokens=*" %%i in ('dir /b /ad "%REPOS_DIR%\*.git" 2^>nul') do (
    set GIT_DIR=%%i
    goto :found_git
)

echo 错误: 未找到 Git 仓库，请先运行 setup.bat
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
echo   ① SVN 从云仓库更新到本地
echo ══════════════════════════════════════════════════════════
echo.

cd /d "%SVN_DIR%"

echo [步骤 1/2] SVN 更新...
echo.
svn update

if errorlevel 1 (
    echo.
    echo ⚠ SVN 更新失败，尝试清理...
    svn cleanup
    svn update
)

if errorlevel 1 (
    echo.
    echo ✗ SVN 更新失败
    pause
    exit /b 1
)

echo.
echo ✓ SVN 更新完成

echo.
echo [步骤 2/2] 提交到 Git...
git add -A

:: 检查是否有变更
for /f %%i in ('git status --porcelain') do (
    goto :has_changes
)

echo ✓ 无变更需要提交
goto :show_next

:has_changes
:: 获取时间戳
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set DATETIME=%%I
set TIMESTAMP=%DATETIME:~0,8%-%DATETIME:~8,6%

git commit -m "sync: SVN update %TIMESTAMP%"
echo ✓ Git 已更新

echo.
echo 最新提交:
git log -1 --oneline

:show_next
echo.
echo ══════════════════════════════════════════════════════════
echo   ② Git 更新到 Worktree
echo ══════════════════════════════════════════════════════════
echo.
echo 当前 Worktree 列表:
git worktree list
echo.
echo 在各 Worktree 执行:
echo   cd C:\work\%PROJECT_NAME%-feature-xxx
echo   git pull origin main
echo.
echo 或一键同步所有 Worktree:
echo   sync-all-worktrees.bat
echo.

pause
