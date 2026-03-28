@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================
:: ② 同步所有 Worktree（从主分支拉取更新）
:: 用法: sync-all-worktrees.bat
:: ============================================

set REPOS_DIR=C:\repos
set WORK_DIR=C:\work

:: 获取项目名称
for /f "tokens=*" %%i in ('dir /b /ad "%REPOS_DIR%\*.git" 2^>nul') do (
    set GIT_DIR=%%i
    goto :found_git
)

echo 错误: 未找到 Git 仓库
exit /b 1

:found_git
set PROJECT_NAME=%GIT_DIR:.git=%
set GIT_REPO=%REPOS_DIR%\%GIT_DIR%
set SVN_DIR=%WORK_DIR%\%PROJECT_NAME%-svn

echo.
echo ══════════════════════════════════════════════════════════
echo   ② Git 更新到所有 Worktree
echo ══════════════════════════════════════════════════════════
echo.

cd /d "%GIT_REPO%"

:: 获取主分支名
git branch --show-current >nul 2>&1
if errorlevel 1 (
    set MAIN_BRANCH=main
) else (
    :: 切换到 SVN 目录检查当前分支
    pushd "%SVN_DIR%"
    for /f "tokens=*" %%b in ('git branch --show-current') do set MAIN_BRANCH=%%b
    popd
)

:: 确保主分支存在
git rev-parse --verify main >nul 2>&1
if errorlevel 1 (
    set MAIN_BRANCH=master
)

echo 主分支: %MAIN_BRANCH%
echo.

:: 列出所有 worktree
set COUNT=0
for /f "tokens=1" %%w in ('git worktree list ^| findstr /v "%PROJECT_NAME%-svn"') do (
    set /a COUNT+=1
    set WORKTREE_!COUNT!=%%w
)

if %COUNT%==0 (
    echo 无其他 Worktree 需要同步
    goto :end
)

echo 找到 %COUNT% 个 Worktree:
echo.

:: 遍历同步
for /l %%i in (1,1,%COUNT%) do (
    set WT=!WORKTREE_%%i!

    :: 显示目录名
    for %%d in ("!WT!") do set WT_NAME=%%~nxd

    echo [!WT_NAME!]
    echo   路径: !WT!

    pushd "!WT!"

    :: 检查当前分支
    for /f "tokens=*" %%b in ('git branch --show-current') do set CURR_BRANCH=%%b

    echo   分支: !CURR_BRANCH!

    :: 合并主分支
    echo   同步中...
    git merge %MAIN_BRANCH% 2>nul

    if errorlevel 1 (
        echo   ⚠ 冲突! 请手动解决:
        echo     cd "!WT!"
        echo     git status
        echo     ... 解决冲突 ...
        echo     git add .
        echo     git commit
    ) else (
        echo   ✓ 已同步
    )

    popd
    echo.
)

:end
echo ══════════════════════════════════════════════════════════
echo   完成
echo ══════════════════════════════════════════════════════════
echo.
echo 现在可以在各 Worktree 继续开发
echo.

pause
