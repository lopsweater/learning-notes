@echo off
chcp 65001 >nul

:: ============================================
:: 快速入门脚本
:: ============================================

echo.
echo ╔══════════════════════════════════════════════════════════╗
echo ║        Git Worktree + SVN 快速入门                       ║
echo ╚══════════════════════════════════════════════════════════╝
echo.
echo 可用命令:
echo.
echo   setup.bat           初始化项目环境
echo   add-worktree.bat    创建新的 Worktree
echo   list-worktrees.bat  列出所有 Worktree
echo   svn-sync.bat        同步 SVN 和 Git
echo   merge-worktree.bat  合并分支到主目录
echo   remove-worktree.bat 删除 Worktree
echo.
echo ══════════════════════════════════════════════════════════
echo.
echo 典型工作流程:
echo.
echo   1. 初始化项目
echo      ^> setup.bat myproject https://svn.company.com/repo/trunk
echo.
echo   2. 创建功能分支
echo      ^> add-worktree.bat feature/new-feature
echo.
echo   3. 开发功能
echo      ^> cd C:\work\myproject-feature-new-feature
echo      ^> ... 编辑代码、编译、测试 ...
echo      ^> git add . ^&^& git commit -m "完成功能开发"
echo.
echo   4. 合并并提交到 SVN
echo      ^> merge-worktree.bat feature/new-feature
echo.
echo   5. 清理已完成的分支
echo      ^> remove-worktree.bat feature/new-feature
echo.
echo ══════════════════════════════════════════════════════════
echo.
echo 目录结构:
echo.
echo   C:\repos\
echo   └── myproject.git\        Git 仓库（裸仓库）
echo.
echo   C:\work\
echo   ├── myproject-svn\        主目录（SVN 同步）
echo   ├── myproject-feature-1\  功能分支 1
echo   └── myproject-feature-2\  功能分支 2
echo.
echo ══════════════════════════════════════════════════════════
echo.
echo 注意事项:
echo.
echo   • SVN 操作只在 myproject-svn 目录进行
echo   • 其他 Worktree 没有 .svn，不能直接操作 SVN
echo   • 使用 Git 分支管理不同功能的开发
echo   • 完成后合并到主目录，再 svn commit
echo.
echo ══════════════════════════════════════════════════════════
echo.

pause
