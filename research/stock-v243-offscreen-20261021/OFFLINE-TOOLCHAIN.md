# 没有网络时怎么把工具链弄上那台 Mac

目标：让那台 Mac 具备 `clang`、`python3`、`git`、`make` 和 macOS SDK。
它们全部来自 **Xcode 命令行工具（Command Line Tools, CLT）**，不需要完整 Xcode。

## 先做一次 30 秒的检查：也许只是没选中

在那台 Mac 的终端里：

```bash
ls -d /Applications/Xcode*.app /Library/Developer/CommandLineTools 2>/dev/null
xcode-select -p
```

- 如果 `ls` 列出了东西但 `xcode-select -p` 没有输出，只是没选中：

```bash
sudo xcode-select -s /Library/Developer/CommandLineTools     # 或 /Applications/Xcode.app
xcode-select -p
xcrun --show-sdk-version
```

这一条如果成功，工具链就有了，直接去跑构建。

## 如果确实什么都没装：用另一台能上网的电脑搬运

那台 Mac 没网，但**你手上这台 Windows 有网**，可以用它下载、拷到 U 盘。

1. 在 Windows 上打开 <https://developer.apple.com/download/all/>（免费 Apple ID 登录）。
2. 搜索 **Command Line Tools for Xcode 16.4**（或与系统匹配的 16.x）。
   下载得到 `Command_Line_Tools_for_Xcode_16.4.dmg`，约 700 MB–1 GB。
3. 把 dmg 拷到 U 盘（E: 或 F: 都行）。
4. 在那台 Mac 上双击 dmg，运行里面的 `Command Line Tools.pkg` 安装。
5. 验证：

```bash
xcode-select -p
xcrun --show-sdk-version      # 需要 >= 15.5
clang --version
python3 -V
git --version
make --version
```

四项都有、SDK ≥ 15.5，就可以离线构建了（源码已经在 U 盘的 `g1-src/` 里）。

## 如果只能拿到完整 Xcode

`Xcode_16.4.xip` 约 10 GB，解压后放到 `/Applications`，然后：

```bash
sudo xcode-select -s /Applications/Xcode.app
sudo xcodebuild -license accept
```

CLT 更小、够用，优先 CLT。

## 需要注意的两点

- **CLT 不带 `xcodebuild`**：构建脚本已经改成"没有 xcodebuild 也继续"，只有 `xcrun`/`clang` 必需。
- **SDK 版本**：低于 15.5 会停（编译参数是 `-mmacosx-version-min=15.5`）。CLT 16.4 对应 macOS 15.5 SDK；若你的 CLT 更老，需要换 16.4。

## 装好之后

```bash
cd ~/Desktop/HONOR-G1-FIRST-TOUCH
bash g1-first-touch.command       # 选 2 构建
```

脚本会自动从 `g1-src/` 取源码、用系统 make 兜底 gmake，不需要网络。
