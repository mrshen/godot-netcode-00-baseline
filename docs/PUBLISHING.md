# 独立发布本章

本章目录自身就是 Git 仓库边界。课程工作区 `D:\syncDemo` 不初始化为一个包含所有章节的大仓库。

## 本地身份与提交

先检查现有身份；已有配置时直接复用：

```bat
.\tools.bat git config user.name
.\tools.bat git config user.email
```

如果尚未配置，可用 `git config --local user.name ...` 和 `git config --local user.email ...` 仅配置本仓库，不改全局设置。

尚未初始化的副本可以执行：

```bat
.\tools.bat git init -b main
.\tools.bat git add .
.\tools.bat git commit -m "feat: add chapter 00 shared Godot world and reproducible tooling"
```

提交前检查 `.godot/`、`artifacts/` 和个人环境配置都未被跟踪。Python、Godot 等工具在仓库外共用，不把二进制、登录信息或个人路径上传。

## GitHub 登录与公开托管

```bat
.\tools.bat gh auth login --hostname github.com --git-protocol https --web
.\tools.bat gh auth status
```

完成浏览器授权后，将下面的 `YOUR_ACCOUNT` 替换为自己的账号或有写入权限的组织，再创建并推送公开仓库：

```bat
.\tools.bat gh repo create YOUR_ACCOUNT/godot-netcode-00-baseline --public --source . --remote origin --push --description "Godot netcode lab chapter 00: shared client/server physics world"
```

若 HTTPS 推送要求凭据，可在当前会话使用 GitHub CLI 凭据助手；不要将令牌写入仓库。`gh auth setup-git` 会修改 Git 凭据配置，只有希望采用该配置时再手动使用。

仓库已经存在时，先核对 `git remote -v` 指向的地址，再进行普通 push；不要强制覆盖已有历史。

## 发布完成后的维护

- 把仓库地址补到工作区索引，并在下一章完成时补全前后章导航。
- 每章内部正常维护 Git 提交；课程学习路径以 README 为准。
- `.github/workflows/verify.yml` 在 Windows runner 的临时目录准备锁定 Godot 并运行无窗口验证。
- GitHub 登录与授权需要仓库所有者本人完成，不能通过仓库文件代替授权。
