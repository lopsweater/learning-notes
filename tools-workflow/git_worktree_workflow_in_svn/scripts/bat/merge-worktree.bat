@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================
:: ③ 合并 Worktree 分支到主 Worktree
:: 用法: merge-worktree.bat <分支名称>
:: ============================================

set REPOS_DIR=C:\repos
set WORK_DIR=C:\work
set BRANCH_NAME=%~1

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

if "%BRANCH_NAME%"=="" (
    echo.
    echo 用法: merge-worktree.bat ^<分支名称^>
    echo.
    echo 可用分支:
    cd /d "%SVN_DIR%"
    git branch -a
    echo.
    exit /b 1
)

echo.
echo ══════════════════════════════════════════════════════════
echo   ③ 合并分支到主 Worktree
echo ══════════════════════════════════════════════════════════
echo.

cd /d "%SVN_DIR%"

echo 项目: %PROJECT_NAME%
echo 分支: %BRANCH_NAME%
echo 目标: %SVN_DIR% (SVN 同步目录)
echo.

:: 检查是否有未提交的变更
for /f %%i in ('git status --porcelain') do (
    echo ⚠ 警告: 主 Worktree 有未提交的变更
    git status -s
    echo.
    set /p CONT="继续合并? (y/n): "
    if /i not "!CONT!"=="y" exit /b 0
)

:: 显示即将合并的提交
echo [预览] 即将合并的提交:
echo.
git log --oneline HEAD..%BRANCH_NAME% 2>nul
echo.

:: 显示文件变更
echo [预览] 文件变更:
git diff --stat HEAD..%BRANCH_NAME% 2>nul
echo.

:: 确认合并
set /p CONFIRM="确认合并? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo 已取消
    exit /b 0
)

:: 执行合并
echo.
echo [合并] git merge %BRANCH_NAME%...
git merge %BRANCH_NAME%

if errorlevel 1 (
    echo.
    echo ══════════════════════════════════════════════════════════
    echo   ⚠ 合并冲突！
    echo ══════════════════════════════════════════════════════════
    echo.
    echo 请手动解决冲突:
    echo.
    echo   1. 查看冲突文件:
    echo      git status
    echo.
    echo   2. 编辑冲突文件，解决标记:
    echo      <<<<<<< HEAD
    echo      当前分支内容
    echo      =======
    echo      %BRANCH_NAME% 内容
    echo      ^>>>>^>>>^> %BRANCH_NAME%
    echo.
    echo   3. 标记已解决:
    echo      git add ^<冲突文件^>
    echo.
    echo   4. 完成合并:
    echo      git commit
    echo.
    echo   5. 重新运行此脚本提交 SVN:
    echo      push-svn.bat
    echo.
    pause
    exit /b 1
)

echo ✓ 合并成功！

:: 检查 SVN 变更
echo.
echo [检查] SVN 状态...
svn status
echo.

:: 询问是否提交 SVN
echo ══════════════════════════════════════════════════════════
echo   下一步
echo ══════════════════════════════════════════════════════════
echo.
echo   ④ 提交到 SVN:
echo      push-svn.bat
echo.
echo   或手动提交:
echo      svn commit -m "提交信息"
echo.

set /p SVN_NOW="是否立即提交 SVN? (y/n): "
if /i "%SVN_NOW%"=="y" (
    push-svn.bat
)

echo.
pause
