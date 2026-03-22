@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================
:: 删除 Worktree
:: 用法: remove-worktree.bat <分支名称|工作目录名>
:: ============================================

set REPOS_DIR=C:\repos
set WORK_DIR=C:\work
set TARGET=%~1

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

if "%TARGET%"=="" (
    echo 用法: remove-worktree.bat ^<分支名称^>
    echo.
    echo 当前 Worktree:
    cd /d "%GIT_REPO%"
    git worktree list
    exit /b 1
)

echo.
echo ============================================
echo   删除 Worktree
echo ============================================
echo.

cd /d "%GIT_REPO%"

:: 查找 worktree 路径
for /f "tokens=1,2" %%a in ('git worktree list --porcelain ^| findstr "worktree"') do (
    set WT_PATH=%%b
    for %%x in ("%%b") do set WT_NAME=%%~nx
    if /i "!WT_NAME:%PROJECT_NAME%-=!"=="%TARGET%" goto :found_path
    if /i "!WT_NAME!"=="%TARGET%" goto :found_path
)

:: 也尝试分支名匹配
for /f "tokens=*" %%p in ('git worktree list ^| findstr /i "%TARGET%"') do (
    for /f "tokens=1" %%x in ("%%p") do set WT_PATH=%%x
    goto :found_path
)

echo 错误: 未找到匹配的 Worktree
echo.
echo 当前列表:
git worktree list
exit /b 1

:found_path
echo 项目: %PROJECT_NAME%
echo 目标: %TARGET%
echo 路径: %WT_PATH%
echo.

:: 检查是否是主目录（含 SVN）
if exist "%WT_PATH%\.svn" (
    echo ⚠ 警告: 这是主工作目录（含 SVN），不建议删除！
    echo.
    set /p FORCE="确认强制删除? (yes/no): "
    if /i not "!FORCE!"=="yes" (
        echo 已取消
        exit /b 0
    )
)

:: 显示未提交的变更
echo 检查未提交的变更...
cd /d "%WT_PATH%"
git status -s

for /f %%i in ('git status --porcelain') do (
    echo.
    echo ⚠ 警告: 存在未提交的变更！
    set /p CONFIRM="仍然删除? (yes/no): "
    if /i not "!CONFIRM!"=="yes" (
        echo 已取消
        exit /b 0
    )
    goto :do_remove
)

:do_remove
echo.
set /p FINAL="确认删除 Worktree 和分支? (y/n): "
if /i not "%FINAL%"=="y" (
    echo 已取消
    exit /b 0
)

:: 删除 worktree
echo.
echo 步骤 1: 删除 Worktree...
cd /d "%GIT_REPO%"
git worktree remove "%WT_PATH%"

if errorlevel 1 (
    echo 错误: 删除失败
    exit /b 1
)

echo ✓ Worktree 已删除

:: 询问是否删除分支
echo.
set /p DEL_BRANCH="是否删除分支 %TARGET%? (y/n): "
if /i "%DEL_BRANCH%"=="y" (
    echo 步骤 2: 删除分支...
    git branch -d "%TARGET%" 2>nul || git branch -D "%TARGET%"
    echo ✓ 分支已删除
)

:: 清理
git worktree prune

echo.
echo ✓ 完成！
echo.
git worktree list

pause
