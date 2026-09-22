# 第 00 章：从零准备环境，运行一个共享物理世界

这套课程会逐步实现一个「客户端先响应输入、服务端计算权威结果、客户端收到结果后纠正预测」的网络同步 Demo。我们会先让问题出现，再加入能够解决它的机制，观察收益和代价。

**第 00 章从零开始，没有上一章。你的任务是准备一套后续章节可以共用的环境，亲手运行客户端和无窗口服务端，并确认它们能使用相同的移动与碰撞规则。** 本章结束时，你应该知道每个工具是做什么的、先运行哪个文件、怎样的输出算成功，以及为什么现在还不能称它为网络同步。

每章都是一个独立仓库，包含完整源码与教程。阅读 README 就能按顺序完成实验，不需要翻聊天记录或 Git log，也不需要下载上一章的源码才能启动本章。

![本章客户端实际运行画面](docs/images/baseline.png)

## 开始之前：我们为什么先做这一章

设想客户端按下向右键，眼前有一面墙。如果客户端用 Godot 检测碰撞，服务端却只做 `位置 += 速度 × 时间`，两端即使使用相同速度，也会得到不同结果：客户端被墙挡住，服务端可能直接走过去。后面做预测与纠正时，这种规则差异会掩盖真正的网络问题。

所以我们先让两端共用地图碰撞数据、角色形状、移动规则和物理设置。Godot 同时承担两端的模拟，客户端额外显示画面，服务端以 Headless 模式运行。这让我们先得到一个可以检查的模拟基线，再引入网络。

有三个概念要先分清：

- **共享代码不等于共享运行时状态。** 客户端和服务端是两个进程，各自拥有自己的角色和物理世界；本章没有通道把一个进程里的输入送给另一个进程。
- **客户端预测和服务端权威是后续职责。** 最终由服务端检查输入是否合法并独立计算结果，客户端可以提前预测。本章只搭建两种运行入口，还没有实现这套网络流程。
- **同一引擎不自动保证完全相同的物理结果。** 本章会用一段固定输入检查指定场景；这不能证明任意机器、版本和动态物理场景都确定一致。[Godot 官方物理说明](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html)

完成本章后，你将能：

1. 在自选目录安装一次 Python 和 Godot，让后续章节继续复用。
2. 通过输出判断版本、工具路径、客户端画面和服务端运行是否正常。
3. 观察角色撞墙、贴墙滑动和斜向移动，理解碰撞世界怎样限制移动。
4. 区分渲染 FPS 与模拟 Tick，并读懂一次双端输入验证的结果。

| 起点有什么问题 | 本章新增什么 | 本章结束仍没有什么 |
| --- | --- | --- |
| 工具路径、版本不统一，难以复现问题 | 版本要求、共享配置、明确的环境检查 | 不承诺任意引擎版本都兼容 |
| 还没有共同的移动与碰撞规则 | 同一份地图、角色模拟和固定逻辑步长 | 复杂地形、移动平台、动态刚体交互 |
| 两个运行角色没有建立起来 | 客户端与无窗口服务端入口、相同录制输入验证 | 连接、消息收发、玩家输入上传 |

## 先看一遍操作顺序

下面的主流程可以直接照着完成。首次学习建议按顺序进行；已经装好工具时，可以跳过对应安装步骤。

| 顺序 | 你要做的事 | 这一步完成的标志 |
| --- | --- | --- |
| 1 | 取得本章源码，选择工具版本和安装包 | 找到 `project.godot`、BAT 入口和附件清单 |
| 2 | 安装 Python，解压 Godot 到自选目录 | 两个 EXE 的 `--version` 都能正常输出 |
| 3 | 配置一次共享工具路径 | `environment.local.bat` 指向真实的 EXE |
| 4 | 运行 `setup.bat` | 出现 `ENVIRONMENT OK: Python and Godot are ready.` |
| 5 | 运行 `run-client.bat`，操作角色 | 画面出现，移动、碰撞、重置正常 |
| 6 | 运行 `run-server.bat --ticks 180` | 无游戏窗口，打印 Tick 后自动退出 |
| 7 | 运行 `verify.bat` | 两端验证完成，末尾出现两行 `PASS` |

**下文命令以 Windows CMD 为准。** 可以按 `Win + R`，输入 `cmd` 打开终端；如果在 VS Code 中操作，选择终端配置里的 `Command Prompt`。示例中的路径都可以替换为你自己的路径。

## 第一步：取得源码和第 00 章附件

如果你已经拿到本章源码，先确认解压后的目录中能找到这些文件：

```text
godot-netcode-00-baseline/
  README.md
  project.godot
  environment.example.bat
  setup.bat
  run-client.bat
  run-server.bat
  verify.bat
  downloads/                  # 环境附件说明和校验清单
  shared/                     # 共用的地图和移动逻辑
```

从 GitHub 获取时，**Code → Download ZIP** 得到源码，解压后再操作里面的文件；也可以用 Git 克隆。GitHub 自动生成的目录可能带 `-main` 后缀，你可以保留它，只要后面进入真实的目录即可。

### 选择版本：哪些可以自定，哪些需要与课程一致

你可以从官网下载自己希望使用的工具版本，并自由选择安装目录。为了让后续实验有可对照的结果，跟课时使用下面的环境要求：

| 工具 / 配置 | 本章如何选择 | 原因 |
| --- | --- | --- |
| Python | **3.11 及以上**；参考环境是 **3.11.9** | 它负责启动和验证脚本；本章只用标准库 |
| Godot | **4.7.2 stable 标准版** | 本章按这一版本验证，启动脚本会检查版本 |
| 游戏语言 | GDScript，随 Godot 提供 | 不需要单独安装语言运行时 |
| 物理 | GodotPhysics2D，**60 Hz** | 两种运行角色按相同设置推进 |
| 渲染 | Compatibility / OpenGL | 本章只做简单 2D 场景 |
| Git、GitHub CLI | 可选，复用已安装版本即可 | 克隆、提交、发布时使用，运行源码 ZIP 不需要 |

本机已验证 Windows 11 x64。Godot 其他版本可以另存到不同目录用于探索，但不属于本章已验证环境；先保留一份 4.7.2 用于跟课。不要仅修改版本清单来绕过检查，那样并没有验证物理和脚本兼容性。

这里的 Python **不写游戏逻辑**。`shared/*.gd` 是 Godot 执行的 GDScript；`scripts/tools.py` 才是 Python 工具。标准版 Godot 运行本章无需 .NET SDK、C# 或 C++ 编译器；VS Code 也不是必需软件。

### 取得安装包

第 00 章提供 [downloads 附件目录](downloads/README.md)，包括文件名、版本、校验值和发布状态。你可以使用课程准备的同版本附件，也可以直接下载官方原文件：

- [Python 3.11.9 Windows x64 安装程序](https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe)：`python-3.11.9-amd64.exe`。
- [Godot 4.7.2 标准版 Windows x64 ZIP](https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip)：`Godot_v4.7.2-stable_win64.exe.zip`。

安装包作为 GitHub Release 的 Assets 分发，**源码 ZIP 不包含这些大文件**。尚未发布附件时，上面的官方链接仍可使用；具体状态见下载目录，避免把“目录里有说明”误认为“附件已经上传”。下载后可以按 [SHA256 校验步骤](downloads/README.md#核对附件完整性) 确认完整性。

安装包的保存位置与软件运行位置是两回事。你可以参考下面的布局，也可以换成其他盘符和目录：

```text
D:\Tools\
  installers\                  # 下载的 EXE/ZIP 原文件
  Python311\python.exe         # 安装完成后的 Python
  Godot\4.7.2\                # 解压完成后的 Godot
D:\syncDemo\
  environment.local.bat        # 所有章节共用的本机路径配置
  godot-netcode-00-baseline\   # 本章源码
  godot-netcode-01-tcp\        # 后续章节，当前不用创建
```

**到这里应当做到：** 你已经知道源码在哪里、需要哪两个工具，并取得了安装包或确认可以复用现有安装。下载完成还不等于环境完成，继续做下面的检查。

## 第二步：安装一次，再检查工具本身

### 2.1 安装或复用 Python

已有 Python 3.11+ 的读者可以直接记录它的 `python.exe` 完整路径，跳过安装。

首次安装时：

1. 打开下载的 `python-3.11.9-amd64.exe`。
2. 选择 **Customize installation**，保留 **pip**。
3. 在高级选项中把安装目录改为你选择的位置，例如 `D:\Tools\Python311`，完成安装。
4. 本课程会显式配置 EXE 路径，不要求你勾选添加到系统 PATH。

在 CMD 中运行，路径不同就替换为自己的路径：

```bat
"D:\Tools\Python311\python.exe" --version
"D:\Tools\Python311\python.exe" -m pip --version
```

参考输出：

```text
Python 3.11.9
pip 24.0 from D:\Tools\Python311\Lib\site-packages\pip (python 3.11)
```

**通过标准：** Python 的版本满足 3.11+，路径指向你选定的安装目录。pip 版本不必与示例逐字一致；本章没有第三方 Python 包，pip 不参与游戏运行，但保留它方便以后安装包依赖。

如果提示找不到文件，先检查 `python.exe` 是否真的存在，再检查命令里的路径和引号。不要因为 PATH 上的 `python` 命令不可用就重复安装，完整路径可以直接运行。

### 2.2 解压 Godot

将 Godot ZIP **完整解压**到自选目录，例如 `D:\Tools\Godot\4.7.2`。目录中应保留：

```text
Godot_v4.7.2-stable_win64.exe
Godot_v4.7.2-stable_win64_console.exe
```

普通 EXE 用于打开编辑器，带 `_console` 的 EXE 便于从终端启动并观察日志。不要只复制其中一个文件，也不要从 ZIP 预览窗口直接运行。

在 CMD 中检查：

```bat
"D:\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe" --version
```

本章参考输出为：

```text
4.7.2.stable.official.ed1daf0bf
```

**通过标准：** 命令正常结束，版本为本章的 `4.7.2.stable`。如果出现另一个版本，先找到正确的 EXE；安装到哪里不重要，启动时选对版本才重要。

完成这一步后，后续章节都复用这套 Python/Godot，不会在每个源码目录里生成 `.tools`。

## 第三步：让章节知道工具在哪里

下面开始在**本章源码目录**操作。先进入该目录：

```bat
cd /d D:\syncDemo\godot-netcode-00-baseline
```

CMD 的 `/d` 用来同时切换盘符和目录。路径有空格时，将整个路径用双引号括起来。

第一次配置时，把示例文件复制到章节共同的上级目录，再打开编辑：

```bat
if not exist ..\environment.local.bat copy environment.example.bat ..\environment.local.bat
notepad ..\environment.local.bat
```

这条复制命令会保留已有配置。后续章节无需重新复制，安装位置发生变化时再修改同一个文件。

把最关键的两行改成自己电脑上的实际路径：

```bat
@echo off
if not defined NETCODE_PYTHON set "NETCODE_PYTHON=D:\Tools\Python311\python.exe"
if not defined NETCODE_GODOT set "NETCODE_GODOT=D:\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe"
```

示例文件还提供 Git 和 GitHub CLI 的配置行，安装了就填写，没安装可以删去对应行。本章主要检查 Python 和 Godot；不用为了看到游戏画面先登录 GitHub。

保存后确认文件放在 `D:\syncDemo\environment.local.bat`，与章节目录并列，**不是放在 `shared`、`scripts` 或安装目录内**。留意记事本不要把它保存成 `environment.local.bat.txt`。

每章 BAT 会读取这份共享配置，变量只作用于这次启动进程，不改系统 PATH。路径中有空格也可以使用上面的 `set "名称=路径"` 写法。

如果工具已在 PATH 上，可以省略配置；如果章节不在同一个父目录，可用 `NETCODE_ENV` 指向同一配置文件。这两种进阶用法见 [环境说明](docs/ENVIRONMENT.md#2-只配置一次路径)。首次跟课先用上面的共同父目录方式即可。

## 第四步：运行环境检查，确认真正准备好了

仍在本章目录的 CMD 中执行：

```bat
.\setup.bat
```

这个入口**只检查已安装的环境，不会替你下载安装软件**。下面摘录成功输出的关键行，实际还会显示操作系统和可选工具信息：

```text
Python: 3.11.9 (D:\Tools\Python311\python.exe)
godot: 4.7.2.stable.official.ed1daf0bf (D:\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe)
requirements.txt: no third-party Python packages required in chapter 00.
Environment check only. No software is downloaded or installed.
ENVIRONMENT OK: Python and Godot are ready.
```

检查输出时关注三点：Python 版本满足要求、Godot 是 4.7.2、两条路径指向你想使用的安装。目录和系统名称可以与作者不同，渲染硬件也不必相同。

**通过标准：** 看到末尾的 `ENVIRONMENT OK: Python and Godot are ready.`。`setup.bat` 随后会等待按键，按任意键返回当前终端；如果双击启动，则结果窗口会关闭。命令行不想等待按键时，可改用 `tools.bat doctor`。

如果没有通过，先处理下面的问题，再继续启动游戏：

| 看到的提示 | 意味着什么 | 先做什么 |
| --- | --- | --- |
| `Python 3.11+ was not found` | 没找到可用的 Python | 检查共享配置位置和 `NETCODE_PYTHON` 的完整路径 |
| `NETCODE_PYTHON must point to a working Python 3.11+ executable` | 指定路径无效或版本过低 | 回到 2.1，用完整路径运行 `--version` |
| `Missing godot` / `Invalid local godot path` | 找不到 Godot EXE | 检查是否完整解压，配置是否指向 `_console.exe` |
| `Expected Godot 4.7.2-stable` | 实际选中了其他引擎版本 | 更正 `NETCODE_GODOT`，再检查输出路径 |
| Git/gh 缺失，但末尾是 `ENVIRONMENT OK` | 仅缺少可选的仓库管理工具 | 可以继续本章的运行实验 |

`requirements.txt` 只管理 Python 包。当前没有额外依赖，不需要运行 `pip install` 或建立虚拟环境；它也不能用来安装 Godot 引擎。

## 第五步：运行客户端，亲手验证移动与碰撞

环境检查通过后，在同一个 CMD 中执行：

```bat
.\run-client.bat
```

此命令会打开游戏窗口，并占用当前终端直到你关闭游戏。先不要在这个终端里继续输入其他命令。

### 先确认画面

你应看到本文开头截图那样的网格地图、三个矩形障碍物，以及出生点处标有 `P1` 的青绿色圆形角色。右侧面板应显示：

- `RUNTIME: CLIENT`，表示当前是客户端运行入口。
- `PHYSICS: 60 Hz`，表示固定逻辑步长设置。
- `SIMULATION TICK` 持续增长，初始位置约为 `168.0 / 404.0`。
- `NETWORK / NOT CONNECTED`，表示本章尚未联网，这是正常状态。

FPS 随电脑、窗口和渲染情况变化，不需要与截图里的数值相同。Tick 是已经执行的逻辑步数，不是渲染帧数。

### 按顺序做三个小实验

| 你怎么操作 | 应该观察到什么 | 这说明什么 |
| --- | --- | --- |
| 从出生点一直按 `D` 或右方向键 | 角色走到中间长墙前停住，X 约为 338；持续顶墙时呈橙色 | 角色实际位置由碰撞世界限制，不能只用坐标相加判断 |
| 在墙边同时按右和上 | 向墙里的分量被挡住，角色可以沿墙向上滑动；离开墙后恢复自由移动 | 移动方向可以分解，碰撞会影响剩余位移 |
| 按 `R`，再在空旷处比较直线与斜向移动 | 回到出生点，Tick 重新从较小数增长；斜向移动不会凭空多出速度 | 重置同时恢复模拟状态；输入向量做了长度限制 |

`WASD` 与方向键都可用。位置示例有小数容差，不要求每一个显示位都完全相同。

**通过标准：** 场景能显示，输入能驱动角色，墙能挡住角色，`R` 能重置。如果窗口出现后立即关闭，或终端出现 `SCRIPT ERROR`，先保留终端报错，检查 Godot 版本及源码是否完整。环境检查成功只证明工具可启动，不能代替这一步的图形检查。

完成观察后，**关闭游戏窗口**，等待 CMD 返回输入提示符，再继续下一步。需要看代码时可使用 `run-client.bat --editor` 打开 Godot 项目；首次运行不要求提前熟悉编辑器。

## 第六步：启动同一物理世界的服务端

先运行一个会自动结束的服务端，避免第一次操作时不知道它何时退出：

```bat
.\run-server.bat --ticks 180
```

你不会看到游戏窗口。终端中会出现类似：

```text
BASELINE role=server physics_hz=60 network=none
SERVER tick=120 position=(168.0, 404.0) (idle; networking begins in chapter 01)
```

它会在完成 180 Tick 后退出，通常约几秒，之后可以继续在终端输入命令。日志每 120 Tick 打印一次，因此不要求看到 `tick=180` 的日志。

**通过标准：** 没有游戏窗口，`role=server` 和 `physics_hz=60` 正确，出现 Tick 日志并正常返回终端。角色位置保持在出生点是预期结果：本章没有来自客户端的网络输入，服务端每步收到零方向输入。

如果想持续运行，使用：

```bat
.\run-server.bat
```

此时它会不断打印 Tick。按 `Ctrl+C` 停止；如果 CMD 询问是否终止批处理，输入 `Y`。

你还可以另开一个 CMD、进入同一章节目录后启动客户端。移动客户端角色时，服务端仍保持原位。**这是本章最需要理解的边界：同一份代码可以被两个进程使用，但输入不会自动跨进程传递。** 下一章就从这个缺口开始。

继续下面的自动验证前，先关闭客户端并停止手动启动的服务端，避免混淆不同进程的日志。

## 第七步：用录制输入检查两种运行角色

现在我们已经分别确认客户端有画面、服务端能独立计算。还需要验证：给两者同一段输入时，它们是否遵循本章预期的移动规则？

在本章目录执行：

```bat
.\verify.bat
```

它会自动完成以下过程，不需要你同时按键：

1. 导入并检查 Godot 项目，捕获脚本错误。
2. 启动客户端入口，按顺序输入向右、向上、左上、向左、向下、静止，共 360 Tick。
3. 启动服务端入口，执行同样的 360 Tick 输入。
4. 检查撞墙、贴墙移动、斜向归一化、边界和静止行为，再比较 6 个检查点的位置与速度。

首次导入会生成 `.godot/` 缓存目录，这是当前项目的导入缓存，不是再次安装引擎；它不会纳入源码 Git 历史。

默认两个入口都以无窗口方式执行，通常需要十几秒，导入项目还会花一些时间。关键输出如下：

```text
VERIFY role=client passed=true ticks=360 samples=6
VERIFY role=server passed=true ticks=360 samples=6
PASS: import, wall collision, sliding, normalized diagonal movement, boundaries, idle.
PASS: both runtime roles matched at 6 checkpoints / 360 ticks (tolerance 0.001).
```

**通过标准：** 两个 `VERIFY` 都是 `passed=true`，并且出现末尾两行 `PASS`。仅看到 Godot 启动标题、只通过客户端或只看到某个中间检查点，都不算完成。

想亲眼看它自动走这段路径，可以运行：

```bat
.\verify.bat --rendered-client
```

这次客户端有画面并自动移动，随后关闭；服务端仍无窗口执行。验证结束后按任意键返回。自动化场景可直接用 `tools.bat verify`，它不暂停等待按键。

详细报告在本机的 `artifacts/verification-client.json` 与 `artifacts/verification-server.json`，相应日志也在 `artifacts/`。失败时先读最后的错误信息，再检查版本、`project.godot` 的 60 Hz 设置、地图与速度参数是否改过；不要用关闭校验的方式让实验“通过”。

这段输入由验证程序直接交给两种运行角色，**不是通过网络发过去的**。通过说明本章场景在当前环境中得到相符的检查点，不能推出“Godot 物理对所有平台都确定一致”，也不能推出“客户端已经和服务端联网”。

## 跑通以后，再顺着输入读代码

先完成上面的运行流程，再按下面顺序阅读，会更容易把代码和现象联系起来：

| 文件 | 你要找的内容 | 对应刚才哪个现象 |
| --- | --- | --- |
| [main.gd](main.gd) | `--role` 如何选择入口，`_physics_process` 如何取得输入并推进世界 | 同一项目可以有客户端画面，也可以无窗口运行 |
| [shared/world.gd](shared/world.gd) | 世界如何创建碰撞体，`step` 如何增加 Tick | 两种入口加载相同地图，每一步都推进模拟 |
| [shared/map_layout.gd](shared/map_layout.gd) | 出生点、边界、三个障碍物的数据 | 为什么出生位置是 168 / 404，墙在哪里 |
| [shared/player.gd](shared/player.gd) | 输入归一化、240 单位/秒的速度、碰撞后的剩余位移 | 为什么撞墙停止、可以滑动、斜向不会更快 |
| [client/presentation.gd](client/presentation.gd) | 读取位置画角色和面板，绘制尾迹与光环 | 画面跟随模拟；表现不反过来修改角色位置 |
| [verification/scenario.gd](verification/scenario.gd) | 固定输入序列及检查点 | 为什么验证能自动发现穿墙或速度错误 |
| [project.godot](project.godot) | 固定 60 Hz 和 Compatibility 渲染配置 | 逻辑步长与渲染帧数分别从哪里来 |

可选练习：找到 `shared/player.gd` 中的 `SPEED`，把 240 暂时改为 120，再运行客户端，观察移动速度变化。完成后恢复为 240 并重新验证。若忘记恢复，验证会因为预期距离不符而失败；这说明验证不只比较两端是否相同，还检查它们是否符合本章规定的行为。

更多设计解释见 [共享世界的结构说明](docs/ARCHITECTURE.md)。Python 工具代码在 [scripts/tools.py](scripts/tools.py)，它负责寻找环境和启动实验，不参与角色物理计算。

## 完成本章的检查清单

进入下一章前，确认你已经完成并理解这些事情：

- [ ] Python 3.11+ 与 Godot 4.7.2 均可启动，安装目录由我自己选择。
- [ ] 共享配置指向真实的 EXE，`setup.bat` 明确显示 `ENVIRONMENT OK`。
- [ ] 客户端能显示地图，角色能移动、被墙挡住、滑动和重置。
- [ ] 服务端无窗口运行，打印正确的角色与 Tick 信息；我知道如何停止它。
- [ ] 验证完成两个 360 Tick 输入序列，显示两行 `PASS`。
- [ ] 我能解释 Python 与 GDScript 的分工、FPS 与 Tick 的区别。
- [ ] 我知道双端共用代码仍未联网，也知道本章验证不等于物理确定性证明。

其中任一步失败，先回到对应步骤处理。这样进入后续网络实验后，才不会把工具版本、图形环境或基础碰撞规则的问题误认为同步算法的问题。

## 下一章会改什么

本章还有一个明确的缺口：客户端的输入和状态都留在自己的进程里，服务端无法收到任何消息。

第 01 章 `godot-netcode-01-tcp`（规划中）会保持本章的引擎、共享模拟规则和环境配置，增加 TCP 连接与消息收发，让你观察连接、断开，以及一串字节如何被还原为完整消息。阅读时重点比较：

| 第 00 章 | 第 01 章计划新增的行为 |
| --- | --- |
| 启动两个互不通信的进程 | 客户端连接服务端，出现连接状态和收发日志 |
| 输入只在各自进程里产生 | 先发送简单实验消息，建立可观察的数据通道 |
| 没有消息格式问题 | 显式处理 TCP 字节流中的消息长度与边界 |

输入上传、服务端计算并广播玩家状态会在第 02 章接入；客户端预测、对账重演随后逐步加入。TCP/UDP 负责传输，KCP 提供可靠传输机制，Protobuf 处理消息序列化，它们解决的问题不同。完整计划见 [课程路线](docs/ROADMAP.md)。

第 01 章将独立提供完整源码，README 会直接说明相对本章的关键行为和文件变化。你可以继续使用这一章准备的共享环境，无需再装一份 Python 和 Godot。

## 延伸资料与许可

- [环境配置细节与常见问题](docs/ENVIRONMENT.md)
- [第 00 章附件与校验清单](downloads/README.md)
- [发布本章仓库和 Release 附件](docs/PUBLISHING.md)

本仓库源码采用 [MIT License](LICENSE)。Godot、Python 等工具保留各自的许可证，环境附件是官方原始文件；相关说明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
