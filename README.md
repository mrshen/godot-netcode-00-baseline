# 第 00 章：环境与共享物理世界

一个逐章学习「客户端预测 + 服务端权威模拟」的 Godot 实验课程。

**本章先建立可信的模拟基线：客户端和无窗口服务端加载同一份地图、碰撞体和移动规则。** 你可以操作角色撞墙、贴墙移动，并用一段录制输入检查两种运行角色的计算结果。

本章没有网络连接。客户端的移动只发生在本地，服务端默认静止等待；不要把同时启动两个进程理解为已经同步。

![第 00 章实际运行画面](docs/images/baseline.png)

## 课程如何组织

每一章是一个独立的 Git/GitHub 仓库，包含完整可运行代码、自己的工具版本锁定和 README。只下载这一章即可运行，不依赖上一章目录，不要求阅读 Git log。

- 当前：`godot-netcode-00-baseline`，环境、固定步长、共享碰撞世界。
- 下一章：`godot-netcode-01-tcp`，规划中，将实现连接和消息边界。
- [完整章节路线](docs/ROADMAP.md)
- [环境配置与版本](docs/ENVIRONMENT.md)
- [结构与设计说明](docs/ARCHITECTURE.md)
- [发布到 GitHub](docs/PUBLISHING.md)

后续 README 会说明「上一章留下什么问题、本章改了什么、如何复现实验、还没解决什么」。章节之间复制必要的源码和资源，保持独立，不使用共享目录软链接或 Git 子模块。

## 环境基线

| 项目 | 本章使用的版本 / 方式 |
| --- | --- |
| 系统 | Windows 11 x64；首次验证构建号 26200 |
| 引擎 | **Godot 4.7.2 stable 标准版**，非 .NET 版 |
| 游戏逻辑 | GDScript，版本随上述 Godot 一起固定 |
| 物理 | GodotPhysics2D，固定 **60 Hz** |
| 渲染 | Compatibility / OpenGL，2D |
| 工具脚本 | **Python 3.11+**，优先复用本机；便携备用版本 **3.14.7**，仅标准库 |
| 启动入口 | Windows BAT；引导使用系统 `curl.exe`、`certutil.exe` 和 `tar.exe` |
| Git | 本机复用 **2.35.1.windows.2**；缺失时安装锁定的 MinGit **2.55.0.windows.5** |
| GitHub CLI | **2.101.0**，发布仓库时使用 |
| 编辑器 | Godot 内置脚本编辑器即可；VS Code 可选 |

不需要 .NET SDK、C#、C++ 编译器、pip 包或 PowerShell 脚本。VS Code 的 GitHub 扩展也不是运行依赖。

独立程序的下载地址及 SHA256 固定在 [toolchain.lock.json](toolchain.lock.json)。Python 包依赖由 [requirements.txt](requirements.txt) 管理，目前只有说明注释，无需安装额外包。Godot 版本严格检查；Python 支持 3.11+，找不到合适的本机版本时 BAT 才下载上述便携备用版本。

## 从零启动

下载并解压本章，或克隆本仓库。建议放到 D 盘，例如：

```text
D:\syncDemo\godot-netcode-00-baseline
```

### 1. 准备工具

双击 `setup.bat`，或在项目目录的终端执行：

```bat
.\setup.bat
```

首次运行优先查找本机 Python 3.11+，缺失时下载便携 Python，随后查找或下载 Godot、Git 和 GitHub CLI，校验下载包的 SHA256，并处理 `requirements.txt`。工具默认位于本章的 `.tools/`，也能复用工作区上层 `.tools/` 中的对应版本。无需管理员权限，不修改注册表、系统 PATH 或系统执行策略。

查看实际使用的版本及路径：

```bat
.\tools.bat doctor
```

已有工具但没有加入 PATH 时，参阅 [本机工具路径配置](docs/ENVIRONMENT.md#复用已经安装的工具)。

### 2. 启动客户端

```bat
.\run-client.bat
```

- `WASD` 或方向键移动。
- `R` 重置位置和模拟 Tick。
- 右侧显示固定物理频率、渲染 FPS、Tick、位置和当前接触状态。
- 青绿色表示自由移动，碰撞时角色变为橙色。
- 关闭游戏窗口退出。

需要查看或修改项目时：

```bat
.\run-client.bat --editor
```

也可以直接使用对应版本的 Godot 打开 `project.godot`。

### 3. 启动服务端

在另一个终端执行：

```bat
.\run-server.bat
```

服务端不创建游戏窗口，但会运行相同的地图碰撞和角色模拟，每 120 Tick 打印一次状态。本章没有网络输入，因此角色保持在出生点；用 `Ctrl+C` 停止。

运行有限的 180 Tick 后自动退出：

```bat
.\run-server.bat --ticks 180
```

### 4. 验证共享模拟

```bat
.\verify.bat
```

验证器先检查项目导入，再把相同的 360 Tick 输入分别送进客户端与服务端运行入口。检查撞墙停止、贴墙移动、斜向输入归一化、地图边界以及无输入时静止，并比较 6 个检查点的位置和速度。

默认两端都无窗口运行。要让客户端在有画面的模式下执行同一场景：

```bat
.\verify.bat --rendered-client
```

通过时末尾显示：

```text
PASS: import, wall collision, sliding, normalized diagonal movement, boundaries, idle.
PASS: both runtime roles matched at 6 checkpoints / 360 ticks (tolerance 0.001).
```

日志与 JSON 报告写入 `artifacts/`，不提交 Git。这个实验验证的是当前机器、版本与场景，不代表 Godot 物理具有跨平台确定性。

首次本地验证（2026-09-22）：Python 3.14.7 的无窗口双端验证通过；Python 3.11.9 的有画面客户端 + 无窗口服务端验证通过。README 截图由实际 Godot 客户端生成。仓库附带 GitHub Actions 配置，其云端结果以 GitHub 上实际运行记录为准。

## 本章要亲手观察的三件事

1. **向右撞中间长墙**：角色会在碰撞体边缘停止，无法穿过。位置由物理世界决定。
2. **贴墙斜向移动**：被墙阻挡的运动分量被消除，沿墙的分量仍可移动；空旷处斜向移动不会比直线更快。
3. **比较 FPS 和 Tick**：渲染刷新与逻辑步进是不同概念；本章逻辑按固定 60 Hz 推进。性能不足时，实际每秒完成的 Tick 仍可能减少。

## 建议的阅读顺序

| 文件 | 读它时关注什么 |
| --- | --- |
| [project.godot](project.godot) | 引擎、窗口、渲染和固定物理频率配置 |
| [main.gd](main.gd) | 客户端/服务端入口如何分开，又如何驱动同一世界 |
| [shared/map_layout.gd](shared/map_layout.gd) | 双端共用的地图碰撞数据 |
| [shared/world.gd](shared/world.gd) | 建立碰撞世界，每个 Tick 接收输入 |
| [shared/player.gd](shared/player.gd) | 输入、速度、碰撞和滑动的关系 |
| [client/presentation.gd](client/presentation.gd) | 表现如何读取模拟状态，不反向修改模拟 |
| [verification/scenario.gd](verification/scenario.gd) | 一段输入如何验证可观察的行为 |
| [scripts/tools.py](scripts/tools.py) | 下载、版本检查、启动、验证等工程工具 |

## 本章边界与下一步

当前只有一个角色和静态碰撞地图；图形由代码绘制，不依赖外部美术资源。移动尾迹和呼吸光环属于表现，不参与模拟。

下一章首先让客户端与服务端建立 TCP 连接，理解字节流为什么需要消息边界。输入上传和服务端权威广播在第 02 章接入。预测、对账、重演会在有明确对照实验之后逐步加入。

## 许可

本仓库代码采用 [MIT License](LICENSE)。Godot 和各项工具保留各自的许可证；工具二进制不纳入本仓库。Godot 的许可说明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。
