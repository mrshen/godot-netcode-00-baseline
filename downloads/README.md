# 第 00 章环境附件

这是课程环境安装包的目录。只需在第 00 章准备一次 Python 和 Godot，后续章节复用同一安装位置。

## 应该下载什么

| 附件文件名 | 版本 / 平台 | 下载后怎么使用 | 官方备用下载 |
| --- | --- | --- | --- |
| `python-3.11.9-amd64.exe` | Python 3.11.9，Windows x64 | 运行安装程序，选择自定义安装位置，保留 pip | [python.org 原文件](https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe) |
| `Godot_v4.7.2-stable_win64.exe.zip` | Godot 4.7.2 标准版，Windows x64 | 完整解压到自选目录，保留里面两个 EXE | [Godot 官方 Release 原文件](https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip) |
| `SHA256SUMS.txt` | 上述两份文件的 SHA256 | 下载后核对完整性 | [查看校验清单](SHA256SUMS.txt) |

已有 Python 3.11+ 的读者可以复用，不必重复安装。Godot 按本章推荐的 4.7.2 跟课；你可以并排保留其他版本用于自己的项目。Git/GitHub CLI 是版本管理工具，不是运行本章 Demo 的必需附件。

## 从哪里取得课程附件

在 [第 00 章 Release：chapter-00-v0.1.0](https://github.com/mrshen/godot-netcode-00-baseline/releases/tag/chapter-00-v0.1.0) 的 **Assets** 中下载两份安装包与 `SHA256SUMS.txt`。附件均已核对 SHA256，也可使用上表的官方备用链接取得相同文件。

GitHub 的 **Code → Download ZIP** 下载的是源码；Release 的 **Assets** 下载的是安装包，两者用途不同。安装包没有加入 Git 历史，因此仅克隆仓库不会得到 EXE/引擎 ZIP；请从 Assets 或上面的官方链接单独取得。

## 下载目录与安装目录分开

建议把下载的原文件保存在自己的公共安装包目录，例如：

```text
D:\Tools\installers\python-3.11.9-amd64.exe
D:\Tools\installers\Godot_v4.7.2-stable_win64.exe.zip
```

再安装/解压到：

```text
D:\Tools\Python311\python.exe
D:\Tools\Godot\4.7.2\Godot_v4.7.2-stable_win64_console.exe
```

这些目录都是示例，你可以使用其他盘符和路径。`downloads` 是附件存放位置，不是让每章运行一套环境的目录。不要从 ZIP 压缩包预览窗口里直接运行 Godot。

## 核对附件完整性

在 Windows CMD 中进入你保存安装包的目录，执行：

```bat
certutil -hashfile python-3.11.9-amd64.exe SHA256
certutil -hashfile Godot_v4.7.2-stable_win64.exe.zip SHA256
```

将输出的十六进制值逐字与 [SHA256SUMS.txt](SHA256SUMS.txt) 对照，大小写不影响比较。两个值都一致，才说明拿到的文件与本章附件一致；如果不同，先确认文件名和版本，再重新获取完整文件，不要修改校验清单来迁就错误下载。

Python 的校验值来自 python.org 发布文件的 Sigstore 元数据，Godot 的校验值来自官方 GitHub Release 资产。原始安装包未修改，保留上游许可与签名。课程源码的 MIT 许可不会替换工具各自的许可。

准备好文件后，回到 [第 00 章 README](../README.md) 的安装步骤继续。安装完成还需要检查环境、启动客户端和服务端、执行验证，不能仅凭下载成功就认为本章完成。
