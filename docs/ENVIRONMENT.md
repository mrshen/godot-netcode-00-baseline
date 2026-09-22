# 环境配置与复现

## 验证环境

记录日期：2026-09-22。版本来自实际执行 `tools.bat doctor`，不是本机未使用软件的清单。

| 组件 | 版本 | 用途 |
| --- | --- | --- |
| Windows | Windows 11 Pro x64，10.0.26200 | 首次验证平台 |
| Godot | 4.7.2.stable.official.ed1daf0bf，标准版 | 客户端、服务端与 GDScript |
| Python | 要求 3.11+；已在 3.11.9 和备用 3.14.7 上运行工具验证 | 工具脚本，无第三方包 |
| Git | 2.35.1.windows.2 | 本机已有版本，复用 |
| MinGit | 2.55.0.windows.5 | 没有现有 Git 时的锁定备用版本 |
| GitHub CLI | 2.101.0 | 登录、建仓、推送辅助 |
| GDScript | 随 Godot 4.7.2 固定 | 无独立安装步骤 |
| GodotPhysics2D | 随 Godot 4.7.2 固定 | 二维碰撞，60 Hz |

GDScript 不需要 .NET。本机存在的 .NET SDK 与本章无关，不要求读者安装或更新。VS Code 只作为可选编辑器，没有必装扩展或版本要求。

## 安装位置

推荐将仓库放在 D 盘。`tools.bat` 优先复用本机 Python 3.11+，缺失时放到本章 `.tools/python-3.14.7`；`setup.bat` 默认也把缺失工具解压到本章 `.tools`。

工具查找顺序：

1. 进程环境变量 `NETCODE_GODOT`、`NETCODE_GIT`、`NETCODE_GITHUB` 指定的可执行文件。
2. 本章的 `.local-tools.json` 对应键。
3. `SYNC_DEMO_TOOLS_DIR` 指向的便携工具目录。
4. 本章 `.tools/`。
5. 本章上级目录的 `.tools/`。
6. 当前进程 PATH 上的 `godot`、`git`、`gh`。

这些工具不写入系统 PATH，不注册服务，不修改注册表或启动项。Godot 自身可能在用户目录生成常规编辑器设置和日志，它们不属于工具安装目录，也不纳入仓库。

如需明确指定共享工具目录，可在项目目录执行：

```bat
.\tools.bat setup --destination D:\syncDemo\.tools
```

## 复用已经安装的工具

在项目根目录创建 `.local-tools.json`，填写本机实际路径。例如：

```json
{
  "git": "D:\\Git\\cmd\\git.exe",
  "godot": "D:\\Tools\\Godot\\Godot_v4.7.2-stable_win64_console.exe"
}
```

只写需要覆盖的键。此文件已被 Git 忽略，个人路径不会上传 GitHub。Godot 必须符合锁定版本；已有 Git 可以使用不同版本，`doctor` 会显示实际版本。

已有 Python 3.11+ 时，可以直接运行：

```bat
python scripts\tools.py doctor
python scripts\tools.py setup
```

也可以在当前 CMD 中指定 Python 的完整路径，让 BAT 跳过便携 Python 引导：

```bat
set "NETCODE_PYTHON=D:\Tools\Python314\python.exe"
.\tools.bat doctor
```

`NETCODE_PYTHON` 指向可执行文件，不是目录。选择顺序为显式指定、已有项目 `.venv`、`py -3`、PATH 中可用的 `python.exe`，最后是便携备用 3.14.7；候选本机 Python 必须为 3.11+。

## requirements.txt 与程序版本清单

`requirements.txt` 管理可由 pip 安装的 Python 包；本章只用标准库，所以文件只有注释。后续有需要时写入 `包名==版本`，由 `setup` 统一安装到本章 `.venv`，避免修改全局 Python 环境。

Godot、Git、GitHub CLI 是独立程序，不属于普通 pip 包。它们由 `toolchain.lock.json` 记录版本、下载地址、校验值，Python 安装器负责下载和解压。两份清单通过同一个 `setup.bat` 入口使用。

便携 embeddable Python 不自带 pip/venv。当前不需要它们；如果未来某章引入第三方包，应选用带 pip/venv 的完整 Python 3.11+，创建项目虚拟环境，并同步更新该章的环境说明。不要为仅使用标准库的当前章节额外安装依赖管理工具。

## 为什么是 BAT + Python

- BAT 负责 Windows 双击入口，以及 Python 尚未安装时的少量引导逻辑。
- Python 负责版本查询、下载校验、ZIP 解压、启动进程和验证报告，只用标准库。
- 引导使用 Windows 自带的 `curl.exe`、`certutil.exe`、`tar.exe`；不依赖 PowerShell 执行策略。
- 不需要 pip 或虚拟环境；Python 不参与游戏的运行逻辑。
- 双击 `setup.bat`、`verify.bat` 后会保留结果窗口；自动化可直接调用 `tools.bat setup/verify`，或设置 `LAB_NO_PAUSE=1`。

Windows 以外的平台目前只可手动使用相同 Godot 版本运行项目；本章的下载清单和 BAT 入口只验证 Windows x64，不宣称跨平台工具安装已完成。

## 下载与锁定

[toolchain.lock.json](../toolchain.lock.json) 固定版本、官方发布地址、压缩包 SHA256 与解压后的可执行文件路径。Python 的首次引导信息同时写在 `tools.bat` 中，因为引导时还不能用 Python 读取 JSON；更新 Python 时必须同步这两处。

Godot、Git 和 GitHub CLI 校验值来自相应 GitHub Release 资产的 SHA256；Python 校验值来自 python.org 对应发布文件的 Sigstore 元数据。本项目执行的是固定 SHA256 比对，不是完整的 Sigstore 签名验证。

官方来源：

- [Godot Windows 下载](https://godotengine.org/download/windows/)
- [Godot 4.7.2 发布文件](https://github.com/godotengine/godot/releases/tag/4.7.2-stable)
- [Python 3.14.7](https://www.python.org/downloads/release/python-3147/)
- [Git for Windows](https://git-scm.com/install/windows)
- [GitHub CLI](https://cli.github.com/)

## 常见问题

**找不到 git，但电脑已安装：** 用 `.local-tools.json` 指定 `git.exe`，然后执行 `tools.bat doctor`。无需改系统 PATH。

**Godot 版本不匹配：** 查看 `doctor` 输出的实际路径，改正本机覆盖配置，或用 `setup --destination` 下载锁定版本。

**下载失败：** 先确认能访问 github.com / python.org。Python 下载器会保留 `.part` 文件，重试时重新下载；BAT 引导下载失败后如果残留的 ZIP 校验不通过，将该文件移开后重试，不要关闭校验。

**首次 GitHub 发布提示未登录：** 执行 `tools.bat gh auth login --hostname github.com --git-protocol https --web`，在浏览器完成授权。不要将访问令牌写入脚本或 README。

**画面打不开：** 客户端使用 Compatibility 渲染器，需要兼容的图形驱动；先运行无窗口的 `tools.bat verify` 区分模拟问题和图形环境问题。
