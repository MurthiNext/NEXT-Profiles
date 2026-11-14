<#
NEXT PowerShell Profile

作者：MurthiNext
日期：2026/11/14
版本：1.2

此配置文件需要 PowerShell 7 及以上版本。
#>

# 配置
$OhMyPoshConfigPath = "$env:USERPROFILE\.config\oh-my-posh\montys.omp.changed.json" # Oh My Posh 配置文件路径
$FastFetchConfigPath = "$env:USERPROFILE\.config\fastfetch\config.jsonc" # FastFetch 配置文件路径
$env:EDITOR = "code --wait" # OpenCode 编辑器

# Oh My Posh
oh-my-posh init pwsh --config $OhMyPoshConfigPath | Invoke-Expression

# 设置 UTF-8 编码
try {
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    chcp 65001 > $null
} catch {}

# PSReadLine 设置
$params = @{
    HistoryNoDuplicates = $true
    ShowToolTips = $true
    BellStyle = "None"
    HistorySearchCursorMovesToEnd = $true
    EditMode = "Windows"
}
# PSReadLine 预测
if ($PSEdition -eq "Core") {
    $params.Add("PredictionSource", "HistoryAndPlugin")
    $params.Add("PredictionViewStyle", "ListView")
}

# 导入模块
Import-Module posh-git
Import-Module ZLocation
Import-Module Terminal-Icons
Import-Module Microsoft.WinGet.CommandNotFound
Import-Module gsudoModule
Set-PSReadLineKeyHandler -Key "Ctrl+z" -Function Undo
Set-PSReadLineKeyHandler -Key "Ctrl+d" -Function ViExit
Set-PSReadLineOption @params

# 启动 Devloper PowerShell 环境
function SetupDevShell {
    Import-Module VSSetup
    Import-Module ((Get-VSSetupInstance)[0].InstallationPath + "\Common7\Tools\Microsoft.VisualStudio.DevShell.dll")
    Enter-VsDevShell -SkipAutomaticLocation -InstanceId (Get-VSSetupInstance)[0].InstanceId
}

# 启动 Python 虚拟环境
function SetupPyVenv {
    # 保存当前执行策略，并在函数结束时恢复
    $originalPolicy = Get-ExecutionPolicy -Scope Process
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    
    try {
        # 获取当前目录
        $currentDir = Get-Location

        # 查找当前目录下所有名称包含 'venv' 的子目录（非递归）
        $venvDirs = Get-ChildItem -Path $currentDir -Directory | Where-Object { $_.Name -like '*venv*' }

        if (-not $venvDirs) {
            Write-Host "未找到包含 'venv' 字样的虚拟环境目录。" -ForegroundColor Yellow
            return
        }

        $selectedVenv = $null

        if ($venvDirs.Count -eq 1) {
            $selectedVenv = $venvDirs[0]
            Write-Host "找到唯一虚拟环境：$($selectedVenv.Name)" -ForegroundColor Green
        }
        else {
            Write-Host "找到多个虚拟环境：" -ForegroundColor Cyan
            for ($i = 0; $i -lt $venvDirs.Count; $i++) {
                Write-Host "[$($i+1)] $($venvDirs[$i].Name)"
            }
            $choice = Read-Host "请输入要激活的环境编号 (1-$($venvDirs.Count))"
            if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $venvDirs.Count) {
                $selectedVenv = $venvDirs[[int]$choice - 1]
            }
            else {
                Write-Host "无效的选择。" -ForegroundColor Red
                return
            }
        }

        # 构建激活脚本路径 (Windows 标准布局)
        $activateScript = Join-Path -Path $selectedVenv.FullName -ChildPath "Scripts\Activate.ps1"
        if (-not (Test-Path $activateScript)) {
            Write-Host "未找到激活脚本：$activateScript" -ForegroundColor Red
            Write-Host "请确认虚拟环境结构是否为标准的 Python venv（包含 Scripts\Activate.ps1）。" -ForegroundColor Yellow
            return
        }

        # 执行激活脚本（点号执行以修改当前会话环境）
        . $activateScript
        Write-Host "已激活虚拟环境：$($selectedVenv.Name)" -ForegroundColor Green

        # 显示当前 Python 路径以确认
        if (Get-Command python -ErrorAction SilentlyContinue) {
            Write-Host "当前 Python 解释器：$(python -c 'import sys; print(sys.executable)')" -ForegroundColor DarkCyan
        }
    }
    finally {
        # 恢复原始执行策略
        Set-ExecutionPolicy -Scope Process -ExecutionPolicy $originalPolicy -Force
    }
}

# 格式化 git 改动中的源码文件
function FormatDiff {
    [CmdletBinding()]
    param(
        [string]$Revision = "HEAD",
        [string[]]$Extension = @(
            ".c", ".h", ".cc", ".cpp", ".cxx", ".hpp", ".hxx", ".hh", ".h++", ".inl", ".ipp",
            ".cu", ".cuh", ".m", ".mm", ".java", ".js", ".ts", ".cs", ".proto"
        )
    )

    if (-not (Get-Command clang-format -ErrorAction SilentlyContinue)) {
        Write-Host "未找到 clang-format，请先安装 LLVM 并加入 PATH。" -ForegroundColor Red
        return
    }

    $repoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $repoRoot) {
        Write-Host "当前目录不在 Git 仓库中。" -ForegroundColor Red
        return
    }
    $repoRoot = $repoRoot.Trim()

    # 尚无提交时与空树比较
    if (-not (git rev-parse --verify -q $Revision 2>$null)) {
        $Revision = "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
    }

    $paths = @(
        git -C $repoRoot -c core.quotepath=off diff --name-only --diff-filter=ACMR -z $Revision
        git -C $repoRoot -c core.quotepath=off ls-files --others --exclude-standard -z
    ) -join "`0"

    $files = $paths -split "`0" |
        Where-Object { $_ -and $Extension -contains [System.IO.Path]::GetExtension($_).ToLower() } |
        ForEach-Object { Join-Path $repoRoot $_ } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        Sort-Object -Unique

    if (-not $files) {
        Write-Host "Git 改动中没有可格式化的源码文件。" -ForegroundColor Yellow
        return
    }

    foreach ($file in $files) {
        clang-format -i --style=file $file
        if ($LASTEXITCODE -eq 0) {
            Write-Host "已格式化 $file" -ForegroundColor Green
        }
        else {
            Write-Host "格式化失败：$file" -ForegroundColor Red
        }
    }
}

# 自定义别名
Set-Alias -Name "devc" -Value SetupDevShell
Set-Alias -Name "devpy" -Value SetupPyVenv
Set-Alias -Name "fmtdiff" -Value FormatDiff

# FastFetch
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch -c $FastFetchConfigPath
}