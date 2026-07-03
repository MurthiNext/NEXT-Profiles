<#
NEXT PowerShell Profile

作者：MurthiNext
日期：2026/07/03
版本：1.1

此配置文件需要 PowerShell 7 及以上版本。

此配置文件实现的功能：
- 设置 UTF-8 编码
- 调整 PSReadLine 设置
- 添加实用的快捷键
- 快速启动 C++ 与 Python 的开发环境
- ……以及下列模块与软件实现的所有功能

需要的 PowerShell 模块：
- posh-git
- ZLocation
- Terminal-Icons
- Microsoft.WinGet.CommandNotFound
- VSSetup

需要提前安装的软件：
- oh-my-posh
- fastfetch
- Microsoft Visual Studio Build Tools
- Python
- gsudo

需要的配置文件（可自行修改替换）：
- $OhMyPoshConfigPath
    - 默认为 montys.omp.changed.json
    - 基于 montys 修改，添加了连接线与 Python 环境显示
- $FastFetchConfigPath
    - 默认为 config.jsonc
    - 基于 examples/26.jsonc 修改，优化了内容与排版
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

# 自定义别名
Set-Alias -Name "devc" -Value SetupDevShell
Set-Alias -Name "devpy" -Value SetupPyVenv

# FastFetch
if (Get-Command fastfetch -ErrorAction SilentlyContinue) {
    fastfetch -c $FastFetchConfigPath
}