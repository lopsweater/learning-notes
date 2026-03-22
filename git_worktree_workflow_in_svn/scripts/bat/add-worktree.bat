@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================
:: 创建新的 Worktree
:: 用法: add-worktree.bat <分支名称> [工作目录名]
:: ============================================

set REPOS_DIR=C:\repos
set WORK_DIR=C:\work
set BRANCH_NAME=%~1
set WORKTREE_NAME=%~2

:: 获取项目名称（从现有的 worktree 推断）
for /f "tokens=*" %%i in ('dir /b /ad "%REPOS_DIR%\*.git" 2^>nul') do (
    set GIT_DIR=%%i
    goto :found_git
)

echo 错误: 未找到 Git 仓库，请先运行 setup.bat
exit /b 1

:found_git
set PROJECT_NAME=%GIT_DIR:.git=%
set GIT_REPO=%REPOS_DIR%\%GIT_DIR%

if "%BRANCH_NAME%"=="" (
    echo 用法: add-worktree.bat ^<分支名称^> [工作目录名]
    echo.
    echo 示例:
    echo   add-worktree.bat feature/login
    echo   add-worktree.bat hotfix/bug-123 fix-123
    echo.
    echo 当前项目: %PROJECT_NAME%
    echo.
    echo 已有的 Worktree:
    cd /d "%GIT_REPO%"
    git worktree list
    exit /b 1
)

:: 如果没有指定工作目录名，使用分支名（替换 / 为 -）
if "%WORKTREE_NAME%"=="" (
    set WORKTREE_NAME=%BRANCH_NAME:/=-%
)

set WORKTREE_PATH=%WORK_DIR%\%PROJECT_NAME%-%WORKTREE_NAME%

echo.
echo ============================================
echo   创建新 Worktree
echo ============================================
echo.
echo 项目:     %PROJECT_NAME%
echo 分支:     %BRANCH_NAME%
echo 目录:     %WORKTREE_PATH%
echo.

if exist "%WORKTREE_PATH%" (
    echo 错误: 目录已存在
    echo   %WORKTREE_PATH%
    exit /b 1
)

cd /d "%GIT_REPO%"
git worktree add "%WORKTREE_PATH%" -b "%BRANCH_NAME%" 2>nul

if errorlevel 1 (
    echo 提示: 分支可能已存在，尝试检出...
    git worktree add "%WORKTREE_PATH%" "%BRANCH_NAME%"
)

if errorlevel 1 (
    echo 错误: 创建失败
    exit /b 1
)

echo.
echo ✓ Worktree 创建成功！
echo.
echo 进入目录:
echo   cd %WORKTREE_PATH%
echo.
echo 完成开发后删除:
echo   remove-worktree.bat %BRANCH_NAME%
echo.

pause
