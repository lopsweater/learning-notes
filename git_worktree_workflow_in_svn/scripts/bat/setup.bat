@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: ============================================
:: Git Worktree + SVN 环境初始化脚本
:: 用法: setup.bat <项目名称> [SVN仓库URL]
:: ============================================

set PROJECT_NAME=%~1
set SVN_URL=%~2
set REPOS_DIR=C:\repos
set WORK_DIR=C:\work

if "%PROJECT_NAME%"=="" (
    echo 用法: setup.bat ^<项目名称^> [SVN仓库URL]
    echo.
    echo 示例:
    echo   setup.bat myproject
    echo   setup.bat myproject https://svn.company.com/repo/trunk
    exit /b 1
)

echo.
echo ============================================
echo   Git Worktree + SVN 环境初始化
echo ============================================
echo.
echo 项目名称: %PROJECT_NAME%
echo Git仓库:  %REPOS_DIR%\%PROJECT_NAME%.git
echo 工作目录: %WORK_DIR%\%PROJECT_NAME%-svn
echo SVN URL:  %SVN_URL%
echo.

:: 创建目录
echo [1/6] 创建目录结构...
if not exist "%REPOS_DIR%" mkdir "%REPOS_DIR%"
if not exist "%WORK_DIR%" mkdir "%WORK_DIR%"

:: 初始化裸仓库
echo [2/6] 初始化 Git 裸仓库...
if exist "%REPOS_DIR%\%PROJECT_NAME%.git" (
    echo    警告: 仓库已存在，跳过初始化
) else (
    git init --bare "%REPOS_DIR%\%PROJECT_NAME%.git"
    echo    ✓ Git 裸仓库创建完成
)

:: 创建主 worktree
echo [3/6] 创建主 Worktree...
cd /d "%REPOS_DIR%\%PROJECT_NAME%.git"
if exist "%WORK_DIR%\%PROJECT_NAME%-svn" (
    echo    警告: 目录已存在，跳过创建
) else (
    git worktree add "%WORK_DIR%\%PROJECT_NAME%-svn"
    echo    ✓ 主 Worktree 创建完成
)

:: 配置 .gitignore
echo [4/6] 配置 .gitignore...
cd /d "%WORK_DIR%\%PROJECT_NAME%-svn"
(
echo .svn/
echo *.o
echo *.obj
echo *.exe
echo *.dll
echo *.so
echo *.dylib
echo *.swp
echo *.swo
echo *~
echo .DS_Store
echo Thumbs.db
echo *.log
echo *.tmp
echo build/
echo dist/
echo node_modules/
) > .gitignore
echo    ✓ .gitignore 创建完成

:: 检出 SVN（如果提供了 URL）
echo [5/6] SVN 检出...
if not "%SVN_URL%"=="" (
    svn checkout "%SVN_URL%" .
    echo    ✓ SVN 检出完成
) else (
    echo    跳过 SVN 检出（未提供 URL）
    echo    你可以稍后手动检出:
    echo      cd %WORK_DIR%\%PROJECT_NAME%-svn
    echo      svn checkout ^<URL^> .
)

:: 创建初始提交
echo [6/6] 创建初始 Git 提交...
cd /d "%WORK_DIR%\%PROJECT_NAME%-svn"
git add .
git commit -m "Init: 项目初始化 $(date +%Y%m%d)" 2>nul
if errorlevel 1 (
    echo    提示: 没有文件可提交或已存在提交
) else (
    echo    ✓ 初始提交完成
)

:: 显示结果
echo.
echo ============================================
echo   初始化完成！
echo ============================================
echo.
echo 目录结构:
echo   %REPOS_DIR%\%PROJECT_NAME%.git     Git 仓库
echo   %WORK_DIR%\%PROJECT_NAME%-svn      主工作目录 (SVN)
echo.
echo 下一步:
echo   1. 添加代码到 %WORK_DIR%\%PROJECT_NAME%-svn
echo   2. 运行 add-worktree.bat 创建开发分支
echo   3. 运行 svn-sync.bat 同步 SVN 更新
echo.

pause
