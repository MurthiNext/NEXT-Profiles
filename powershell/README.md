# NEXT PowerShell Profile

### Yes! 这是 MurthiNext 本人正在使用且精心编写的 PowerShell 配置文件，其正在强势维护中，与一般的配置文件不同，在花里胡哨的同时，也要追求实用！

## 此配置文件实现的功能：
- 设置 UTF-8 编码
- 调整 PSReadLine 设置
- 添加实用的快捷键
   - Ctrl+Z 撤销
   - Ctrl+D ViExit
- 快速启动 C++ 与 Python 的开发环境
   - 键入 `devc` 命令以启动 `Devloper PowerShell` 环境
   - 键入 `devpy` 命令以快速启动当前目录下的 Python 虚拟环境（支持多个虚拟环境的选择）
- ……以及下列模块与软件实现的所有功能

## 初次使用需要配置的内容
### 需要的 PowerShell 模块：
- posh-git
- ZLocation
- Terminal-Icons
- Microsoft.WinGet.CommandNotFound
- VSSetup

### 需要提前安装的软件：
- oh-my-posh
- fastfetch
- Microsoft Visual Studio Build Tools
- Python
- gsudo

### 需要的配置文件（可自行修改替换）：
- $OhMyPoshConfigPath
    - 默认为 montys.omp.changed.json
    - 基于 montys 修改，添加了连接线与 Python 环境显示
- $FastFetchConfigPath
    - 默认为 config.jsonc
    - 基于 examples/26.jsonc 修改，优化了内容与排版