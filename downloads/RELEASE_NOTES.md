# 第 00 章：环境与共享物理世界

从零配置一次共享 Python/Godot 环境，运行本地角色移动与碰撞，再启动使用相同模拟规则的无窗口服务端。

## 附件

- `python-3.11.9-amd64.exe`：Python 3.11.9 Windows x64 官方安装程序；已有 Python 3.11+ 可复用。
- `Godot_v4.7.2-stable_win64.exe.zip`：Godot 4.7.2 标准版 Windows x64 官方压缩包。
- `SHA256SUMS.txt`：安装包完整性校验值。

源码从仓库或本 Release 的 Source code 下载；上面两份附件是工具安装包，不是游戏可执行文件。安装目录可以自定，后续章节共用。按仓库 README 依次完成：安装 → 共享路径配置 → `setup.bat` → `run-client.bat` → `run-server.bat --ticks 180` → `verify.bat`。

本章客户端和服务端尚未联网。验证通过说明本章指定场景的两种运行角色计算结果相符，不意味着 Godot 物理具有跨平台确定性。
