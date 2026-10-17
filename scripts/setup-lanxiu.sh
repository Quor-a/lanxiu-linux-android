#!/bin/sh
# 一键在 Termux / 安卓设备上搭建 LANXIU Linuxaarch64 proot 环境
#
# 拉取对应当前 x86_64 LANXIU ISO 1.7.41（release 307）的「LANXIU 安卓版」完整 rootfs：
#   lanxiu-aarch64-rootfs-20261017.tar.xz
# 该 rootfs 在 LANXIU aarch64 全量包基础上，已加入 44 个交叉编译到 aarch64 的当前版应用
# （qydesktop 桌面 / qyfiles 文件 / qymedia 媒体 / qynet 网络 / qysettings 设置 /
#   qycalc 计算器 / qyclock 时钟 / qynote 笔记 / qyshot 截图 / qymon 监视 /
#   qystore 商店 / qyview 看图 / qysudo 授权 / qynotifd 通知 等）。
#
# 用法: sh setup-lanxiu.sh [目标目录]
# 默认目录: ~/lanxiu-root
set -e
BASE=https://github.com/Quor-a/lanxiu-linux-aarch64/releases/latest/download
DEST=${1:-$HOME/lanxiu-root}
TARBALL=lanxiu-aarch64-rootfs-20261017.tar.xz

mkdir -p "$DEST" && cd "$DEST"
echo "==> 下载 LANXIU 安卓版 rootfs（$TARBALL）"
curl -fL --retry 5 --retry-delay 2 -C - -o "$TARBALL" "$BASE/$TARBALL"
echo "==> 解包到 $DEST"
tar -xJf "$TARBALL" && rm -f "$TARBALL"

echo
echo "==> 完成。已部署 LANXIU 安卓版 rootfs: $DEST"
echo "  进入终端环境:"
echo "    proot -r $DEST -0 -b /dev -b /proc -b /sys /usr/bin/bash -l"
echo "  启动桌面（需安卓侧 X11/Wayland 转发）:"
echo "    proot -r $DEST -0 -b /dev -b /proc -b /sys -b /sdcard:/media/sdcard env DISPLAY=:0 /usr/bin/qydesktop"