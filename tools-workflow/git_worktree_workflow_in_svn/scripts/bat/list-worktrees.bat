@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================
:: 列出所有 Worktree
:: 用法: list-worktrees.bat
:: ============================================

set REPOS_DIR=C:\repos

:: 获取项目名称
for /f "tokens=*" %%i in ('dir /b /ad "%REPOS_DIR%\*.git" 2^>nul') do (
    set GIT_DIR=%%i
    goto :found_git
)

echo 错误: 未找到 Git 仓库，请先运行 setup.bat
exit /b 1

:found_git
set PROJECT_NAME=%GIT_DIR:.git=%

echo.
echo ============================================
echo   Worktree 列表
echo ============================================
echo.
echo 项目: %PROJECT_NAME%
echo.

cd /d "%REPOS_DIR%\%GIT_DIR%"
git worktree list

echo.
echo 分支列表:
git branch -vv

echo.
pause
