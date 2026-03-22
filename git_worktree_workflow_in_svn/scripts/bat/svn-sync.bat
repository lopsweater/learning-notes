@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================
:: SVN 同步脚本
:: 用法: svn-sync.bat [push|pull]
::   pull  - 从 SVN 拉取更新到 Git
::   push  - 将 Git 变更提交到 SVN
:: ============================================

set REPOS_DIR=C:\repos
set WORK_DIR=C:\work
set MODE=%~1

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
echo ============================================
echo   SVN 同步
echo ============================================
echo.
echo 项目: %PROJECT_NAME%
echo 目录: %SVN_DIR%
echo.

cd /d "%SVN_DIR%"

if "%MODE%"=="push" goto :push_to_svn
if "%MODE%"=="commit" goto :push_to_svn
if "%MODE%"=="pull" goto :pull_from_svn
if "%MODE%"=="update" goto :pull_from_svn

:: 默认：双向同步
echo 选择操作:
echo   [1] 从 SVN 拉取更新 (pull)
echo   [2] 提交到 SVN (push)
echo   [3] 查看状态
echo.
set /p CHOICE="请选择 (1/2/3): "

if "%CHOICE%"=="1" goto :pull_from_svn
if "%CHOICE%"=="2" goto :push_to_svn
if "%CHOICE%"=="3" goto :show_status
echo 无效选择
exit /b 1

:pull_from_svn
echo.
echo [从 SVN 拉取更新]
echo.

:: SVN 更新
echo 步骤 1: svn update...
svn update
if errorlevel 1 (
    echo 错误: SVN 更新失败
    exit /b 1
)

:: 检查是否有变更
for /f %%i in ('git status --porcelain') do (
    goto :has_changes
)
echo ✓ SVN 无变更
goto :end

:has_changes
:: Git 提交
echo.
echo 步骤 2: 提交到 Git...
git add -A

:: 获取日期时间
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set DATETIME=%%I
set TIMESTAMP=%DATETIME:~0,8%-%DATETIME:~8,6%

git commit -m "sync: SVN update %TIMESTAMP%"
echo ✓ Git 提交完成

:: 显示日志
echo.
echo 最新提交:
git log -1 --oneline
goto :end

:push_to_svn
echo.
echo [提交到 SVN]
echo.

:: 显示待提交的文件
echo 步骤 1: 检查 SVN 状态...
svn status

echo.
set /p CONFIRM="确认提交? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo 已取消
    exit /b 0
)

:: 输入提交信息
echo.
set /p COMMIT_MSG="输入提交信息: "
if "%COMMIT_MSG%"=="" (
    for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set DATETIME=%%I
    set COMMIT_MSG=Update %DATETIME:~0,8%
)

echo.
echo 步骤 2: svn commit...
svn commit -m "%COMMIT_MSG%"
if errorlevel 1 (
    echo 错误: SVN 提交失败
    exit /b 1
)

:: 记录到 Git
echo.
echo 步骤 3: 记录到 Git...
git add -A
git commit -m "Submitted to SVN: %COMMIT_MSG%" 2>nul

echo ✓ SVN 提交完成
goto :end

:show_status
echo.
echo [SVN 状态]
svn status

echo.
echo [Git 状态]
git status -s

echo.
echo [当前分支]
git branch -v
goto :end

:end
echo.
pause
