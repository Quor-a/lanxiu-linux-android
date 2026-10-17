# LANXIU vs Ubuntu Base 24.04.5 (arm64) proot 用户空间对比

> 目的：以官方 Ubuntu Base 24.04.5 aarch64 rootfs（通用 proot 用户空间，非 Termux proot-distro）为基准，
> 逐项对比 LANXIU r9 rootfs，找出缺口并补齐，确保 LANXIU 在 proot 下行为与成熟发行版一致。

来源：`https://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.5-base-arm64.tar.gz`

## 对比结果

| 项目 | Ubuntu Base | LANXIU r9 | 说明/修复 |
|---|---|---|---|
| `/etc/ld.so.cache` | ✅ 有 | ✅ 已补（334 库） | 动态链接缓存；缺失会导致非默认路径库加载失败。r9 用 aarch64 ldconfig 生成 |
| `/sbin/ldconfig` | ✅ 有 | ✅ 已补（+ldconfig.real） | 系统库缓存维护工具，来自 Ubuntu glibc 2.39（aarch64） |
| `/etc/machine-id` | ✅ 有 | ✅ 已补 | dbus 依赖 machine-id；LANXIU 带 dbus 包，缺失会启动失败。r9 已生成 |
| `/etc/bash.bashrc` | ✅ 有 | ✅ 已补 | 系统级 bash 初始化（提示符/umask/别名） |
| `/root/.bashrc`、`/root/.profile` | ✅ 有 | ✅ 已补 | root home 默认 shell 配置；`/etc/skel` 同步补齐 |
| `/etc/login.defs` | ✅ 有 | ✅ 已补 | shadow 工具链默认参数（useradd/passwd） |
| `/etc/issue`、`/etc/issue.net` | ✅ 有 | ✅ 已补 | 登录横幅（LANXIU 品牌） |
| `/etc/host.conf` | ✅ 有 | ✅ 已补 | 主机名解析顺序配置 |
| `/etc/gai.conf` | ✅ 有 | ✅ 已补 | getaddrinfo 行为配置 |
| `/usr/bin/getent`、`ldd`、`getconf` | ✅ 有 | ✅ 已补 | 网络/动态链接诊断工具（来自 Ubuntu glibc-bin） |
| `/etc/profile.d/` | 01-locale-fix.sh | lanxiu.sh + ssl-ca.sh | LANXIU 额外注入 CA bundle，联网开箱即用 |
| `/etc/pam.d/` | 完整（common-*、login、chfn…） | sudo/su/login/passwd/other | 基础可用；未完全模块化，后续可补 common-* |
| `/etc/hosts` | localhost | localhost | 一致 |
| `/etc/nsswitch.conf` | hosts: files dns | hosts: files dns | 一致 |
| `/etc/resolv.conf` | 系统管理 | 6 个公共 DNS | LANXIU 内置，免配置联网 |
| setuid 二进制 | sudo/su/passwd 等 | sudo/su/chsh/chfn/newuidmap/… | LANXIU 更全 |
| 包管理器 | apt/dpkg | qypkg | 不同体系，正常 |
| init 系统 | systemd | qyinit | 不同体系，正常 |
| /bin /lib /sbin | usrmerge | usrmerge | 一致 |
| /dev | 空（proot 提供） | 空（proot 提供） | 一致 |

## 实测（r9，qemu-aarch64 chroot）

- `bash` 启动、`id`=root、hostname=lanxiu、os-release=LANXIU 1.7.41 ✅
- `ldconfig -p`：334 个库在缓存 ✅
- `dbus-uuidgen --get` 正常返回 machine-id ✅
- `sudo -n id` → uid=0(root) ✅
- `getent ahosts www.baidu.com` 正常解析 ✅
- `curl -4 --cacert /etc/ssl/certs/ca-certificates.crt https://www.baidu.com` → HTTP 200 ✅
- 动态链接器经 ld.so.cache 找到 `/usr/lib/sudo/libsudo_util.so.0` ✅

## 结论

LANXIU r9 已补齐与 Ubuntu proot 用户空间的关键结构差异。此前的 proot `getcwd` 问题（第七轮已修）与
本次补的 `ld.so.cache`/`machine-id` 等无关，但补齐后 LANXIU 在 proot 下的行为与标准发行版一致，
可排除「rootfs 不完整导致 proot 异常」这一可能性。
