#!/data/data/com.termux/files/usr/bin/sh
# Termux 一键搭 LANXIU proot 环境
#
# 默认：下载组装好的完整 rootfs（35+ 包，17 项启动自检全过）——推荐，
#       一个 24MB 的 tar.xz 一次搞定，无需逐包下载。
# 加 --pkgs：改用逐包 .qyp 方式（自定义包集时用），传法不变。
set -e
command -v proot >/dev/null || pkg install -y proot
command -v curl  >/dev/null || pkg install -y curl
DIR=$(cd "$(dirname "$0")" && pwd)
if [ "$1" = "--pkgs" ]; then
  exec sh "$DIR/fetch-rootfs.sh" --pkgs "${2:-$HOME/qyroot}" \
    glibc-2.39-2.aarch64.qyp \
    ncurses-6.5-1.aarch64.qyp \
    readline-8.3-1.aarch64.qyp \
    pcre2-10.45-1.aarch64.qyp \
    zlib-1.3.1-1.aarch64.qyp \
    zstd-1.5.7-1.aarch64.qyp \
    xz-5.8.1-1.aarch64.qyp \
    busybox-1.36.1-1.aarch64.qyp \
    bash-5.3-1.aarch64.qyp \
    grep-3.11-1.aarch64.qyp \
    sed-4.9-1.aarch64.qyp \
    tar-1.35-1.aarch64.qyp \
    which-2.23-1.aarch64.qyp \
    diffutils-3.11-1.aarch64.qyp \
    file-5.46-1.aarch64.qyp \
    procps-ng-4.0.5-1.aarch64.qyp \
    less-668-1.aarch64.qyp \
    findutils-4.10.0-1.aarch64.qyp \
    gawk-5.3.1-1.aarch64.qyp \
    util-linux-2.41-1.aarch64.qyp
fi
exec sh "$DIR/fetch-rootfs.sh" "${1:-$HOME/qyroot}"
