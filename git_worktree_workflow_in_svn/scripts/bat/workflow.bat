@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================
:: 一键工作流
:: 用法: workflow.bat <步骤>
::   start  - 开始新的一天 (①+②)
::   finish - 完成功能 (③+④)
::   full   - 完整流程 (①+②+③+④)
:: ============================================

set STEP=%~1

if "%STEP%"=="" (
    echo.
    echo ══════════════════════════════════════════════════════════
    echo   一键工作流
    echo ══════════════════════════════════════════════════════════
    echo.
    echo   用法: workflow.bat ^<步骤^>
    echo.
    echo   start   开始新的一天
    echo           ① SVN 更新 + ② Git 同步到所有 Worktree
    echo.
    echo   finish  完成功能开发
    echo           ③ 合并分支 + ④ SVN 提交
    echo.
    echo   full    完整流程
    echo           ① SVN 更新 + ② Git 同步 + ③ 合并 + ④ SVN 提交
    echo.
    echo   示例:
    echo     workflow.bat start
    echo     workflow.bat finish
    echo.
    exit /b 0
)

:: ============================================
:: 开始新的一天
:: ============================================
if /i "%STEP%"=="start" (
    echo.
    echo ══════════════════════════════════════════════════════════
    echo   开始新的一天
    echo   ① SVN 更新 + ② Git 同步
    echo ══════════════════════════════════════════════════════════
    echo.

    :: ① SVN 更新
    call pull-svn.bat

    if errorlevel 1 (
        echo ✗ SVN 更新失败
        exit /b 1
    )

    :: ② Git 同步
    call sync-all-worktrees.bat

    echo.
    echo ══════════════════════════════════════════════════════════
    echo   ✓ 准备就绪！
    echo ══════════════════════════════════════════════════════════
    echo.
    echo   现在可以开始开发:
    echo     cd C:\work\project-feature-xxx
    echo.
    exit /b 0
)

:: ============================================
:: 完成功能开发
:: ============================================
if /i "%STEP%"=="finish" (
    set BRANCH_NAME=%~2

    if "!BRANCH_NAME!"=="" (
        echo.
        echo 用法: workflow.bat finish ^<分支名称^>
        echo.
        echo 当前分支:
        cd /d "%SVN_DIR%"
        git branch -a
        echo.
        exit /b 1
    )

    echo.
    echo ══════════════════════════════════════════════════════════
    echo   完成功能开发
    echo   ③ 合并分支 + ④ SVN 提交
    echo ══════════════════════════════════════════════════════════
    echo.

    :: ③ 合并分支
    call merge-worktree.bat !BRANCH_NAME!

    if errorlevel 1 (
        echo ✗ 合并失败
        exit /b 1
    )

    echo.
    echo ══════════════════════════════════════════════════════════
    echo   ✓ 功能已完成并提交 SVN！
    echo ══════════════════════════════════════════════════════════
    echo.
    echo   清理分支:
    echo     remove-worktree.bat !BRANCH_NAME!
    echo.
    exit /b 0
)

:: ============================================
:: 完整流程
:: ============================================
if /i "%STEP%"=="full" (
    set BRANCH_NAME=%~2

    echo.
    echo ══════════════════════════════════════════════════════════
    echo   完整工作流
    echo   ① SVN 更新 → ② Git 同步 → ③ 合并 → ④ SVN 提交
    echo ══════════════════════════════════════════════════════════
    echo.

    :: ① SVN 更新
    call pull-svn.bat
    if errorlevel 1 exit /b 1

    :: ② Git 同步
    call sync-all-worktrees.bat
    if errorlevel 1 exit /b 1

    :: 询问要合并的分支
    if "!BRANCH_NAME!"=="" (
        echo.
        echo 可用分支:
        git branch -a
        echo.
        set /p BRANCH_NAME="输入要合并的分支名: "
    )

    if "!BRANCH_NAME!"=="" (
        echo 已取消
        exit /b 0
    )

    :: ③ 合并分支
    call merge-worktree.bat !BRANCH_NAME!
    if errorlevel 1 exit /b 1

    echo.
    echo ══════════════════════════════════════════════════════════
    echo   ✓ 完成！
    echo ══════════════════════════════════════════════════════════
    echo.
    exit /b 0
)

echo 未知步骤: %STEP%
echo.
echo 可用步骤: start, finish, full
exit /b 1
