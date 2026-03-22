# ============================================
# Git Worktree + SVN 管理脚本 (PowerShell)
# 四步工作流: ① SVN更新 → ② Git同步 → ③ 开发合并 → ④ SVN提交
# ============================================

param(
    [Parameter(Position=0)]
    [string]$Command,

    [Parameter(Position=1, ValueFromRemainingArguments)]
    [string[]]$Arguments
)

$ErrorActionPreference = "Stop"
$ReposDir = "C:\repos"
$WorkDir = "C:\work"

function Get-ProjectName {
    $gitDirs = Get-ChildItem -Path $ReposDir -Filter "*.git" -Directory -ErrorAction SilentlyContinue
    if ($gitDirs) {
        return $gitDirs[0].Name -replace '\.git$'
    }
    return $null
}

function Get-GitRepo {
    $projectName = Get-ProjectName
    if ($projectName) {
        return Join-Path $ReposDir "$projectName.git"
    }
    return $null
}

function Get-SvnDir {
    $projectName = Get-ProjectName
    if ($projectName) {
        return Join-Path $WorkDir "$projectName-svn"
    }
    return $null
}

function Show-Header($title) {
    Write-Host ""
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Show-Success($message) {
    Write-Host "✓ $message" -ForegroundColor Green
}

function Show-Error($message) {
    Write-Host "✗ $message" -ForegroundColor Red
}

function Show-Info($message) {
    Write-Host "  $message" -ForegroundColor Yellow
}

function Show-Step($step, $message) {
    Write-Host "[$step] $message" -ForegroundColor Yellow
}

# ============================================
# 初始化项目
# ============================================
function Initialize-Project {
    param(
        [string]$ProjectName,
        [string]$SvnUrl
    )

    if (-not $ProjectName) {
        Show-Error "请指定项目名称"
        Write-Host "用法: .\worktree.ps1 init <项目名称> [SVN URL]"
        return
    }

    Show-Header "初始化项目"

    Write-Host "项目名称: $ProjectName"
    Write-Host "Git 仓库: $ReposDir\$ProjectName.git"
    Write-Host "工作目录: $WorkDir\$ProjectName-svn"
    Write-Host "SVN URL:  $SvnUrl"
    Write-Host ""

    # 创建目录
    if (-not (Test-Path $ReposDir)) { New-Item -ItemType Directory -Path $ReposDir | Out-Null }
    if (-not (Test-Path $WorkDir)) { New-Item -ItemType Directory -Path $WorkDir | Out-Null }

    # 初始化裸仓库
    $gitRepo = Join-Path $ReposDir "$ProjectName.git"
    if (Test-Path $gitRepo) {
        Show-Info "Git 仓库已存在"
    } else {
        git init --bare $gitRepo
        Show-Success "Git 裸仓库创建完成"
    }

    # 创建主 worktree
    $svnWorktree = Join-Path $WorkDir "$ProjectName-svn"
    Push-Location $gitRepo
    if (Test-Path $svnWorktree) {
        Show-Info "工作目录已存在"
    } else {
        git worktree add $svnWorktree
        Show-Success "主 Worktree 创建完成"
    }
    Pop-Location

    # 配置 .gitignore
    Push-Location $svnWorktree
    $gitignore = @(
        ".svn/",
        "*.o", "*.obj", "*.exe", "*.dll", "*.so", "*.dylib",
        "*.swp", "*.swo", "*~",
        ".DS_Store", "Thumbs.db",
        "*.log", "*.tmp",
        "build/", "dist/", "node_modules/"
    )
    $gitignore -join "`n" | Out-File -FilePath ".gitignore" -Encoding utf8
    Show-Success ".gitignore 创建完成"

    # SVN 检出
    if ($SvnUrl) {
        svn checkout $SvnUrl .
        Show-Success "SVN 检出完成"
    } else {
        Show-Info "跳过 SVN 检出"
    }

    # 初始提交
    git add .
    git commit -m "Init: 项目初始化 $(Get-Date -Format 'yyyyMMdd')" 2>$null
    Show-Success "初始化完成"

    Pop-Location

    Write-Host ""
    Show-Header "下一步"
    Write-Host "  创建开发分支: .\worktree.ps1 add feature/xxx"
    Write-Host "  ① SVN 更新:   .\worktree.ps1 pull"
    Write-Host ""
}

# ============================================
# ① SVN 更新
# ============================================
function Pull-Svn {
    $svnDir = Get-SvnDir

    if (-not $svnDir -or -not (Test-Path "$svnDir\.svn")) {
        Show-Error "未找到 SVN 工作副本"
        return
    }

    Show-Header "① SVN 从云仓库更新到本地"

    Push-Location $svnDir

    Show-Step "1/2" "SVN 更新..."
    svn update

    if ($LASTEXITCODE -ne 0) {
        Show-Error "SVN 更新失败，尝试清理..."
        svn cleanup
        svn update
    }

    Show-Success "SVN 更新完成"

    Show-Step "2/2" "提交到 Git..."
    git add -A

    $status = git status --porcelain
    if ($status) {
        git commit -m "sync: SVN update $(Get-Date -Format 'yyyyMMdd-HHmm')"
        Show-Success "Git 已更新"
        git log -1 --oneline
    } else {
        Show-Info "无变更"
    }

    Pop-Location

    Write-Host ""
    Show-Header "② 下一步: Git 同步到 Worktree"
    Write-Host "  同步所有: .\worktree.ps1 sync-all"
    Write-Host "  或手动:   cd C:\work\project-feature-xxx"
    Write-Host "           git pull origin main"
    Write-Host ""
}

# ============================================
# ② Git 同步到所有 Worktree
# ============================================
function Sync-AllWorktrees {
    $gitRepo = Get-GitRepo
    $svnDir = Get-SvnDir

    if (-not $gitRepo) {
        Show-Error "未找到 Git 仓库"
        return
    }

    Show-Header "② Git 更新到所有 Worktree"

    Push-Location $svnDir
    $mainBranch = git branch --show-current
    Pop-Location

    Write-Host "主分支: $mainBranch"
    Write-Host ""

    Push-Location $gitRepo

    $worktrees = git worktree list --porcelain
    $count = 0

    foreach ($line in $worktrees) {
        if ($line -match '^worktree (.+)$') {
            $path = $matches[1]
            $name = Split-Path $path -Leaf

            # 跳过 SVN 目录
            if ($name -match '-svn$') { continue }

            $count++
            Write-Host "[$name]"
            Write-Host "  路径: $path"

            Push-Location $path
            $branch = git branch --show-current
            Write-Host "  分支: $branch"

            Write-Host "  同步中..." -NoNewline
            git merge $mainBranch 2>$null

            if ($LASTEXITCODE -eq 0) {
                Write-Host " ✓" -ForegroundColor Green
            } else {
                Write-Host " ⚠ 冲突" -ForegroundColor Yellow
                Write-Host "  请手动解决: cd $path && git status"
            }

            Pop-Location
            Write-Host ""
        }
    }

    Pop-Location

    if ($count -eq 0) {
        Show-Info "无其他 Worktree 需要同步"
    }

    Write-Host ""
    Show-Success "同步完成"
    Write-Host ""
}

# ============================================
# 添加 Worktree
# ============================================
function Add-Worktree {
    param(
        [string]$BranchName,
        [string]$WorktreeName
    )

    if (-not $BranchName) {
        Show-Error "请指定分支名称"
        Write-Host "用法: .\worktree.ps1 add <分支名称> [工作目录名]"
        return
    }

    $projectName = Get-ProjectName
    $gitRepo = Get-GitRepo

    if (-not $projectName) {
        Show-Error "未找到项目"
        return
    }

    if (-not $WorktreeName) {
        $WorktreeName = $BranchName -replace '/', '-'
    }

    $worktreePath = Join-Path $WorkDir "$projectName-$WorktreeName"

    Show-Header "创建 Worktree"

    Write-Host "项目: $projectName"
    Write-Host "分支: $BranchName"
    Write-Host "目录: $worktreePath"
    Write-Host ""

    if (Test-Path $worktreePath) {
        Show-Error "目录已存在: $worktreePath"
        return
    }

    Push-Location $gitRepo
    git worktree add $worktreePath -b $BranchName 2>$null
    if ($LASTEXITCODE -ne 0) {
        git worktree add $worktreePath $BranchName
    }
    Pop-Location

    Show-Success "Worktree 创建完成"
    Write-Host ""
    Write-Host "进入目录: cd $worktreePath"
    Write-Host "完成后:   .\worktree.ps1 merge $BranchName"
    Write-Host ""
}

# ============================================
# ③ 合并分支
# ============================================
function Merge-Branch {
    param([string]$BranchName)

    if (-not $BranchName) {
        Show-Error "请指定分支名称"
        Write-Host "用法: .\worktree.ps1 merge <分支名称>"
        return
    }

    $svnDir = Get-SvnDir

    Show-Header "③ 合并分支到主 Worktree"

    Push-Location $svnDir

    Write-Host "分支: $BranchName"
    Write-Host "目标: $svnDir (SVN 同步目录)"
    Write-Host ""

    # 显示差异
    Write-Host "[预览] 即将合并的提交:"
    git log --oneline HEAD..$BranchName 2>$null
    Write-Host ""
    git diff --stat HEAD..$BranchName 2>$null
    Write-Host ""

    $confirm = Read-Host "确认合并? (y/n)"
    if ($confirm -ne "y") {
        Write-Host "已取消"
        Pop-Location
        return
    }

    Write-Host ""
    Write-Host "[合并] git merge $BranchName..."
    git merge $BranchName

    if ($LASTEXITCODE -eq 0) {
        Show-Success "合并成功"

        Write-Host ""
        Write-Host "[检查] SVN 状态:"
        svn status
        Write-Host ""

        $svnCommit = Read-Host "④ 是否立即提交 SVN? (y/n)"
        if ($svnCommit -eq "y") {
            Push-Svn
        }
    } else {
        Show-Error "合并冲突，请手动解决"
        Write-Host "  git status"
        Write-Host "  ... 解决冲突 ..."
        Write-Host "  git add ."
        Write-Host "  git commit"
    }

    Pop-Location
    Write-Host ""
}

# ============================================
# ④ SVN 提交
# ============================================
function Push-Svn {
    $svnDir = Get-SvnDir

    if (-not $svnDir -or -not (Test-Path "$svnDir\.svn")) {
        Show-Error "未找到 SVN 工作副本"
        return
    }

    Show-Header "④ SVN 提交"

    Push-Location $svnDir

    Write-Host "[检查] Git 状态:"
    git status -s
    Write-Host ""

    Write-Host "[检查] SVN 状态:"
    svn status
    Write-Host ""

    $status = svn status
    if (-not $status) {
        Show-Info "无 SVN 变更需要提交"
        Pop-Location
        return
    }

    $message = Read-Host "输入 SVN 提交信息"
    if (-not $message) {
        $message = "Update $(Get-Date -Format 'yyyyMMdd')"
    }

    Write-Host ""
    Write-Host "[提交] svn commit..."
    svn commit -m $message

    if ($LASTEXITCODE -eq 0) {
        Show-Success "SVN 提交成功"

        Write-Host ""
        Write-Host "[记录] 提交到 Git..."
        git add -A
        git commit -m "已提交 SVN: $message" 2>$null
    } else {
        Show-Error "SVN 提交失败"
    }

    Pop-Location
    Write-Host ""
}

# ============================================
# 列出 Worktree
# ============================================
function Get-Worktrees {
    $gitRepo = Get-GitRepo
    if (-not $gitRepo) {
        Show-Error "未找到项目"
        return
    }

    Show-Header "Worktree 列表"

    Push-Location $gitRepo
    git worktree list
    Write-Host ""
    Write-Host "分支列表:"
    git branch -vv
    Pop-Location
    Write-Host ""
}

# ============================================
# 删除 Worktree
# ============================================
function Remove-Worktree {
    param([string]$BranchName)

    if (-not $BranchName) {
        Show-Error "请指定分支名称"
        return
    }

    $gitRepo = Get-GitRepo
    $projectName = Get-ProjectName

    Show-Header "删除 Worktree"

    Push-Location $gitRepo

    # 查找 worktree
    $worktrees = git worktree list --porcelain
    $worktreePath = $null

    foreach ($line in $worktrees) {
        if ($line -match '^worktree (.+)$') {
            $path = $matches[1]
            $name = Split-Path $path -Leaf
            if ($name -like "*$BranchName*") {
                $worktreePath = $path
                break
            }
        }
    }

    if (-not $worktreePath) {
        Show-Error "未找到匹配的 Worktree"
        git worktree list
        Pop-Location
        return
    }

    Write-Host "路径: $worktreePath"

    # 检查 SVN 目录
    if (Test-Path "$worktreePath\.svn") {
        Show-Error "这是主工作目录，不能删除！"
        Pop-Location
        return
    }

    # 检查未提交变更
    Push-Location $worktreePath
    $status = git status --porcelain
    if ($status) {
        Write-Host "未提交的变更:"
        git status -s
    }
    Pop-Location

    $confirm = Read-Host "确认删除? (y/n)"
    if ($confirm -eq "y") {
        git worktree remove $worktreePath
        Show-Success "Worktree 已删除"

        $delBranch = Read-Host "是否删除分支 $BranchName? (y/n)"
        if ($delBranch -eq "y") {
            git branch -d $BranchName 2>$null
            if ($LASTEXITCODE -ne 0) {
                git branch -D $BranchName
            }
            Show-Success "分支已删除"
        }

        git worktree prune
    }

    Pop-Location
    Write-Host ""
}

# ============================================
# 显示帮助
# ============================================
function Show-Help {
    Write-Host ""
    Write-Host "Git Worktree + SVN 管理脚本" -ForegroundColor Cyan
    Write-Host "四步工作流: ① SVN更新 → ② Git同步 → ③ 开发合并 → ④ SVN提交" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "用法: .\worktree.ps1 <命令> [参数]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "初始化:"
    Write-Host "  init <项目> [URL]    初始化项目"
    Write-Host "  add <分支> [名称]    创建 Worktree"
    Write-Host ""
    Write-Host "工作流:"
    Write-Host "  ① pull               SVN 更新到本地"
    Write-Host "  ② sync-all           Git 同步到所有 Worktree"
    Write-Host "  ③ merge <分支>       合并分支到主目录"
    Write-Host "  ④ push               SVN 提交"
    Write-Host ""
    Write-Host "管理:"
    Write-Host "  list                 列出所有 Worktree"
    Write-Host "  remove <分支>        删除 Worktree"
    Write-Host "  help                 显示帮助"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  .\worktree.ps1 init myproject https://svn.company.com/repo"
    Write-Host "  .\worktree.ps1 add feature/login"
    Write-Host "  .\worktree.ps1 pull"
    Write-Host "  .\worktree.ps1 sync-all"
    Write-Host "  .\worktree.ps1 merge feature/login"
    Write-Host "  .\worktree.ps1 push"
    Write-Host ""
}

# ============================================
# 主入口
# ============================================
switch ($Command) {
    "init"      { Initialize-Project -ProjectName $Arguments[0] -SvnUrl $Arguments[1] }
    "add"       { Add-Worktree -BranchName $Arguments[0] -WorktreeName $Arguments[1] }
    "pull"      { Pull-Svn }
    "sync-all"  { Sync-AllWorktrees }
    "merge"     { Merge-Branch -BranchName $Arguments[0] }
    "push"      { Push-Svn }
    "list"      { Get-Worktrees }
    "remove"    { Remove-Worktree -BranchName $Arguments[0] }
    "help"      { Show-Help }
    default     { Show-Help }
}
