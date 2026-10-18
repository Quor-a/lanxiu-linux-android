# LANXIU Linux · 安卓移植层

把**LANXIU Linux**（Quor-a/lanxiu-linux）的 aarch64 用户空间搬到安卓设备上运行。

安卓与普通 ARM64 Linux 的差别不在 CPU 指令（都是 aarch64），而在**用户空间接口**：
安卓用的是 bionic libc + 特有链接器，不是 glibc。本仓库提供三条落地路径。

## LANXIU 安卓版 rootfs（对应当前开发版）

**LANXIU 安卓版 rootfs**：在 LANXIU aarch64 全量包基础上，把当前版的 44 个应用
交叉编译成 aarch64 后整体打包，供 zorvAI 终端 / Termux proot 直接使用。
**联网已开箱即用**（DNS/NSS/CA 已内置，curl/wget/openssl HTTPS 实测通过）。

**一键搭建（Termux）：**

```sh
pkg install proot
curl -LO https://raw.githubusercontent.com/Quor-a/lanxiu-linux-android/main/scripts/setup-lanxiu.sh
sh setup-lanxiu.sh
proot -r ~/lanxiu-root -0 -b /dev -b /proc -b /sys /usr/bin/bash -l
```

内含应用（均已交叉编译为 aarch64）：

- 桌面/系统：`qydesktop` 桌面、`qyappmenu` 应用菜单、`qynotifd` 通知、`qysudo` 授权、
  `qysettings` 设置、`qysetup` 首次配置、`qylock` 锁屏、`qyswitcher` 窗口切换、`qyboot` 开机
- 常用工具：`qyfiles` 文件、`qynet` 网络、`qymedia` 媒体、`qyview` 看图、`qyshot` 截图、
  `qymon` 系统监视、`qycalc` 计算器、`qyclock` 时钟、`qynote` 笔记、`qytodo` 待办、
  `qystore` 应用商店、`qypkg-inst` 包安装、`qybackup` 备份、`qydisk` 磁盘、`qysearch` 搜索
- 其他：`qybrowser` 浏览器、`qyaudio` 音量、`qyweather` 天气、`qyedit` 编辑器、`qymime` 类型、
  `qyrec` 录音、`qycolor` 取色、`qyconvert` 转换、`qyclip` 剪贴板、`qyhelp` 帮助、`qyusers` 用户等
- 命令行/终端工具（aarch64 交叉编译，本轮补齐）：
  `git 2.49.0`、`iproute2`（`ip`/`ss`/`tc`）、`iw`、`alsa-utils`（`amixer`/`aplay`）、
  `unzip`、`p7zip`（`7za`/`7z`）、`shadow`（`useradd`/`passwd`/`usermod`）、`sudo`、`tzdata`

> rootfs 文件名：`lanxiu-aarch64-rootfs-20261017.tar.xz`（**本仓库 Release**，tag `lanxiu-1.7.41-aarch64`）

>
> **完善记录**：
> - 第二轮：清理原包 x86_64 git 污染（544MB）；补齐 `qyaudio`/`qyweather`；新增 git 2.49.0；
>   精简 python 测试/缓存与多余 locale；全部 ELF 复核为 aarch64。
> - 第三轮：按应用运行时依赖补齐命令行工具 —— `ip`（qynet 网络配置）、`iw`（WiFi 扫描）、
>   `amixer`（桌面音量）、`unzip`/`7za`（文件/压缩管理器）、`useradd`/`passwd`/`sudo`（用户与提权）、
>   `tzdata`（时区）。qemu-aarch64 + chroot 实测全部可运行。
> - 第四轮：**联网开箱即用**。补齐 `/etc/resolv.conf`（6 个 DNS）、`/etc/nsswitch.conf`（`hosts: files dns`）、
>   `/etc/ssl/certs` CA 证书（121 张 + rehash 哈希链接 + `ca-certificates.crt` bundle）；
>   新增 `/etc/profile.d/ssl-ca.sh` 注入 `SSL_CERT_FILE`/`CURL_CA_BUNDLE`（curl 的 OpenSSL 后端不读目录，
>   必须给 bundle 文件路径）。实测：`curl` 百度/GitHub 200、`wget` OK、`openssl s_client` 目录模式验证 OK。
> - 第五轮：**全面统一品牌为 LANXIU**。`/etc/os-release`、`/etc/hostname`、`qystore.desktop` 及 weston/gtk/ld 配置全部改为 LANXIU，源码/文档同步清理。
> - 第六轮：**sudo 修复可用**。补齐 `/etc/pam.d/`（sudo/su/login/passwd/other）与 `/etc/shadow`，chroot 下 `sudo -n id` 实测正常；`qyinit` 启动横幅同步改为澜岫 Linux。
> - 第七轮：**proot cwd 兼容修复**。rootfs 预建 `/data/user/0/...`、`/data/local/tmp`、`/storage/emulated/0`、`/sdcard` 等安卓宿主路径（guest 内可见、权限兼容普通 uid），proot 继承宿主 cwd 启动时 `getcwd` 不再失败。
> - 第八轮：**对齐 Ubuntu proot 用户空间**。以官方 Ubuntu Base 24.04.5 arm64 为基准逐项对比（见 [docs/UBUNTU-PROOT-COMPARE.md](docs/UBUNTU-PROOT-COMPARE.md)），补齐 `/etc/ld.so.cache`（334 库）、`/sbin/ldconfig`、`/etc/machine-id`（dbus 必需）、`/etc/bash.bashrc`、`/root/.bashrc`、`/etc/login.defs`、`/etc/issue`、`/etc/host.conf`、`/etc/gai.conf`、`getent`/`ldd`/`getconf` 等。
>
> 📦 安卓不需要的包统计见 [docs/ANDROID-UNNEEDED.md](docs/ANDROID-UNNEEDED.md)（约 60MB 可选剔除）。

## 三条路径

| 路径 | 需要 root | 原理 | 适用 |
|---|---|---|---|
| **A. proot** | 否 | ptrace 拦截系统调用，把路径重定向到目录 | 普通手机、快速试用 |
| **B. chroot** | 是 | 直接切根，性能最好 | 已 root 设备、开发板 |
| **C. 原生启动** | 是 | 刷 boot.img 启动 LANXIU 内核 | 深度定制设备 |

三条路共用同一套 **aarch64 .qyp 包**：
https://github.com/Quor-a/lanxiu-linux-aarch64

## 已知限制

- **嵌套 proot 无法再启动第二个 rootfs**：安卓的 ptrace 安全策略会拒绝嵌套 proot，所以 LANXIU 不能在现有 Ubuntu proot 环境里再套一层运行，目前只能作为文件独立存在，或等 App 内的发行版切换器支持后直接切换。
- **sudo 已可用**：rootfs 内置完整 PAM 配置（`/etc/pam.d/`）和 `/etc/shadow`，chroot 下 `sudo -n id` 实测正常。已 root 设备建议走 chroot 路径；proot 下直接 `proot -0` 以 root 身份操作即可。
- **定位说明**：LANXIU 不是安卓 root 环境，而是**交叉编译的 aarch64 用户空间（rootfs）**，通过 proot 在普通安卓设备上运行（无需 root）；proot 内以 root（`proot -0`）身份运行，home 为 `/root`。

## 快速开始（路径 A：proot，无需 root）

```sh
# 1. 在 Termux 里安装 proot
pkg install proot

# 2. 一键拉取并解包完整基础环境（glibc + busybox + bash + 常用工具，约 20 包）
curl -LO https://raw.githubusercontent.com/Quor-a/lanxiu-linux-android/main/scripts/setup-proot.sh
sh setup-proot.sh

# 或分步：下载包后用 qyextract.sh 解包（.qyp = 128 字节头 + gzip tar 数据段）
# sh qyextract.sh <包.qyp> [目标目录]

# 3. 进入 LANXIU 环境
proot -r ~/qyroot -0 -b /dev -b /proc -b /sys /usr/bin/bash
```

进入后即是 LANXIU Linux 的 aarch64 用户空间：glibc 运行时 + bash/grep/sed/tar 等。
注意：**glibc 包必须最先解包**（其余动态链接包都依赖它）。

## 路径 B：chroot（已 root）

```sh
su -c "
  mkdir -p /data/qyroot
  # 解包同上到 /data/qyroot
  mount -t proc proc /data/qyroot/proc
  mount -t sysfs sys /data/qyroot/sys
  chroot /data/qyroot /usr/bin/busybox sh
"
```

## 路径 C：原生启动（刷机）

主仓库的 `bin/qyandroid` 负责打包安卓引导镜像：

```sh
# 打包 boot.img（内核 + ramdisk + dtb）
python3 bin/qyandroid bootimg \
  --kernel Image.gz --ramdisk ramdisk.img --dtb board.dtb \
  --cmdline "console=ttyMSM0" --out boot.img

# 打包前自检（页大小/魔数/AVB 一致性——安卓刷错直接变砖）
python3 bin/qyandroid verify boot.img

# 生成 fastboot 刷机脚本（会明确警告解锁会清空数据）
python3 bin/qyandroid super --root-mb 3072
```

⚠️ **刷机风险**：解锁 bootloader 会**清空全部用户数据**，且各厂商解锁政策不同。
请先备份，并确认设备有可用的救砖手段（fastboot 镜像、官方固件包）。

## 已知限制

- 安卓的 **bionic libc** 与 glibc 不兼容：本仓库包是 glibc 目标（aarch64-linux-gnu），
  必须经 proot/chroot 提供 glibc 运行时，不能直接丢进安卓 `/system/bin`。
- verified boot 设备上 `/system` 只读，写入需 overlay 或改刷 GSI。
- 无 root 设备只能走路径 A（proot），性能约为原生 60–80%。

## 目录

- `scripts/setup-proot.sh` — 一键在 Termux 里搭好 LANXIU proot 环境（默认下载完整 rootfs tar.xz，`--pkgs` 逐包）
- `scripts/chroot-enter.sh` — 已 root 设备的 chroot 进入脚本
- `scripts/fetch-rootfs.sh` — 从包仓库拉取并解包根文件系统（完整 tar.xz、`--lanxiu` 或逐包 .qyp）
- `scripts/qyextract.sh` — 解包单个 .qyp（解析 QYPKG 头 + 完整性校验）

## 安卓 APK（内置 LANXIU）

- **`lanxiu-aarch64-1.7.41.apk`**（约 95MB）：可直接安装的测试 APK，内置：
  - aarch64 静态 proot 二进制
  - r10 LANXIU rootfs（93MB xz，首次启动自动解压（v3：改用 bionic 编译的 proot（Termux 版），内置 libtalloc.so.2/libandroid-shmem.so，设置 LD_LIBRARY_PATH，修复 glibc 静态版被安卓 seccomp 杀(SIGSYS)的问题））
  - 启动后自动以 `proot -0 -r <rootfs> /bin/bash` 运行，显示 id/uname/os-release
- 包名：`com.lanxiu.android`；minSdk 24 / targetSdk 34；仅支持 arm64-v8a 设备
- 用途：验证 LANXIU rootfs 在真实安卓设备 proot 环境下的行为（定位原 App 的 proot bug 是否为 App 侧问题）

## 下载

- **proot Root 用户空间数据 ISO**：本仓库 Release → `lanxiu-aarch64-1.7.41.iso`（挂载后 `proot -0 -r <解压目录> /bin/bash` 使用）
- **r10 rootfs（推荐）**：本仓库 Release → `lanxiu-aarch64-rootfs-20261017.tar.xz`（直接解压后 `proot -0 -r <目录> /bin/bash` 运行）
- **单包按需**：aarch64 包仓库 Release 的 `*.aarch64.qyp`（58 个，含 python3.13/openssl/curl/dbus 等）
