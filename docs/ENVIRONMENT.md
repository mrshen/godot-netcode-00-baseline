# 一次配置，多章复用

Python、Godot、Git 都安装在章节目录之外，安装位置由你决定。每章只保存源码、版本要求和启动脚本，不下载或携带一套引擎、Python，也不创建 `.tools`。

下面以 Windows x64、D 盘为例。没有 D 盘时，选择其他目录并修改路径即可。

## 版本与官方下载

| 组件 | 本章版本要求 / 已验证版本 | 官方安装包或说明 |
| --- | --- | --- |
| Python | **3.11+**；当前验证 **3.11.9** | [3.11.9 x64 安装程序](https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe) · [发布页](https://www.python.org/downloads/release/python-3119/) |
| Godot | **4.7.2 stable 标准版**，非 .NET | [Windows x64 ZIP](https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip) · [发布页](https://github.com/godotengine/godot/releases/tag/4.7.2-stable) |
| Git | 已验证 **2.35.1.windows.2**；可复用已有 Git | [Git for Windows](https://git-scm.com/install/windows) |
| GitHub CLI | 已验证 **2.101.0**；只在发布时需要 | [Windows x64 ZIP](https://github.com/cli/cli/releases/download/v2.101.0/gh_2.101.0_windows_amd64.zip) |

GDScript 和 GodotPhysics2D 随 Godot 版本固定，无需单独安装。客户端使用 Compatibility / OpenGL，物理频率 60 Hz。首次验证系统为 Windows 11 Pro x64，构建号 26200。

这里提供官方文件链接，安装包无需重复提交进每章 Git 仓库。需要离线分发时，可以将相同文件作为 Release 附件，保留原始文件名、许可证和校验值。[toolchain.lock.json](../toolchain.lock.json) 记录版本及安装包 SHA256，章节脚本只用它检查版本，不自动下载安装。

## 1. 安装一次

推荐的目录结构：

```text
D:\Tools\
  Python311\python.exe
  Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe
  GitHubCLI\2.101.0\bin\gh.exe
  installers\                       # 安装包可留在这里，供离线使用
D:\Git\cmd\git.exe                  # 可复用已有 Git
D:\syncDemo\
  environment.local.bat              # 本机路径只配置一次
  godot-netcode-00-baseline\
  godot-netcode-01-tcp\               # 后续章节
```

**Python：** 已有 3.11+ 就直接使用。新安装时打开官方 EXE，选择 `Customize installation`，保留 pip，在高级选项中把安装位置改为自己的工具目录，例如 `D:\Tools\Python311`。本课程不要求修改系统 PATH，使用下文共享配置即可。官方完整安装程序会执行常规的软件注册；由你根据自己的电脑情况运行安装。

**Godot：** 将 ZIP 解压到自己选择的目录即可。标准版不需要 .NET SDK 或 C++ 编译器；编辑器和无窗口服务端使用同一套引擎文件。

**Git / GitHub CLI：** 已有环境直接复用。下载源码 ZIP 后运行 Demo 不依赖这两项工具；克隆、提交和发布仓库时才需要。

本机已经准备好的共享 Python 3.11.9 来自 CPython 官方 [NuGet 包](https://www.nuget.org/packages/python/3.11.9)，解压到 `D:\Tools\Python311`，具备 pip 和 venv，不是之前缺少 pip 的 embeddable 包。该发行包侧重脚本/构建用途，不带 IDLE 等界面工具。它无需运行安装程序或修改注册表；如果你自行配置电脑，使用上面的完整 EXE 安装方式同样适用。[Python 官方 Windows 发行方式说明](https://docs.python.org/3.11/using/windows.html)

## 2. 只配置一次路径

从本章复制 [environment.example.bat](../environment.example.bat) 到**所有章节共同的上级目录**，重命名为 `environment.local.bat`，修改里面的路径：

```bat
@echo off
if not defined NETCODE_PYTHON set "NETCODE_PYTHON=D:\Tools\Python311\python.exe"
if not defined NETCODE_GODOT set "NETCODE_GODOT=D:\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe"
if not defined NETCODE_GIT set "NETCODE_GIT=D:\Git\cmd\git.exe"
if not defined NETCODE_GITHUB set "NETCODE_GITHUB=D:\Tools\GitHubCLI\2.101.0\bin\gh.exe"
```

未安装的可选工具可以删去对应行。每章的 BAT 入口会加载同一份上级配置，这些变量只作用于当前启动进程，不写系统环境变量或注册表。

如果章节放在不同位置，可以在当前 CMD 中设置 `NETCODE_ENV` 指向同一个配置文件：

```bat
set "NETCODE_ENV=D:\syncDemo\environment.local.bat"
D:\OtherProjects\godot-netcode-00-baseline\tools.bat doctor
```

如果你的工具已经在 PATH 中，则不必使用配置文件。Python 查找顺序为 `NETCODE_PYTHON`、`py -3`、PATH 中有效的 `python.exe`，必须满足 3.11+；Godot/Git/gh 使用对应 `NETCODE_*` 变量或 PATH。找不到工具时会报出安装说明，**不会自动下载**。

修改安装位置时只需更新这份共享配置。后续章节需要不同 Godot 版本时，可在 `Godot/` 下并排保留版本，再为该章节启动进程覆盖 `NETCODE_GODOT`；不覆盖已有引擎。

## 3. 检查并运行

在任意章节目录执行：

```bat
.\setup.bat
.\run-client.bat
```

`setup.bat` 现在只检查环境，不下载、安装软件或创建虚拟环境。`tools.bat doctor` 执行同样的检查，适合命令行使用；双击 `setup.bat` 会保留结果窗口。

输出应指向你选定的共享目录。Godot 不符合本章要求或不可用时，检查返回非零退出码；Git/gh 缺失只提示它们是可选工具。

## Python 依赖怎样管理

`requirements.txt` 管理 Python 包依赖，不能代替 Python/Godot 本身的安装。本章只使用标准库，因此没有额外的包，也不需要 `.venv`。

后续某章确实引入第三方包时，该章会注明版本和安装命令。必要的虚拟环境只隔离 Python 包，不复制整套 Godot，也不要求重新安装基础 Python。避免为所有章节强行安装同一批可能冲突的包。

## 本机验证与自动化

- 当前本机共享 Python：`D:\Tools\Python311\python.exe`，3.11.9，pip 24.0。
- 当前本机共享 Godot：`D:\Tools\Godot\4.7.2`，4.7.2.stable.official.ed1daf0bf。
- 当前本机 Git：`D:\Git`；GitHub CLI：`D:\Tools\GitHubCLI\2.101.0`。
- 安装包集中在 `D:\Tools\installers`；个人路径不提交到章节仓库。
- GitHub Actions 使用临时 runner 的公共工具环境，下载 Godot 到 `RUNNER_TEMP`，不会把引擎放进源码仓库。

本章工具支持 Windows x64。其他平台可以手动用相同 Godot 版本运行项目，当前不宣称跨平台工具配置已验证。

## 常见问题

**找不到 Python/Godot：** 检查共享配置里的完整 EXE 路径。Python 的目录本身不能代替 `python.exe`；Godot 建议使用带 `_console.exe` 的可执行文件以便保留日志。

**原来有 `.local-tools.json` 或 `.tools`：** 这是旧的逐章安装方式。先配置共享环境，确认 `doctor` 和 `verify` 通过，再清理你自己创建的重复工具文件。新版脚本不读取旧目录。

**刚把工具加入 PATH，终端仍找不到：** 新开一个终端，或直接使用共享配置文件指定路径。

**GitHub 连接超时：** Python 工具会将 Windows 已有 HTTP/HTTPS 代理传给 Git/gh 子进程；不会修改系统代理，已有进程代理环境变量优先。

**画面打不开：** Compatibility 渲染器需要可用的图形驱动；先运行 `tools.bat verify` 的无窗口验证，区分模拟问题和图形环境问题。
