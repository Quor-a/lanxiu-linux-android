#!/bin/sh
# 获取 LANXIU aarch64 根文件系统
#
# 默认：直接下载组装好的完整 rootfs（55+ 包，已验证可直接用）——推荐。
# 加 --lanxiu：下载「LANXIU 安卓版」完整 rootfs（对应当前 x86_64 ISO 1.7.41 / release 307，
#              含 42 个当前版应用交叉编译产物）。
# 加 --pkgs：改为逐包下载 .qyp 再解包（自定义包集时用）。
#
# 用法: ./fetch-rootfs.sh [目标目录]
#       ./fetch-rootfs.sh --lanxiu [目标目录]
#       ./fetch-rootfs.sh --pkgs [目标目录] [包名...]
set -e
BASE=https://github.com/Quor-a/lanxiu-linux-aarch64/releases/latest/download
DIR=$(cd "$(dirname "$0")" && pwd)

if [ "$1" = "--lanxiu" ]; then
  shift
  DEST=${1:-$HOME/lanxiu-root}
  TARBALL=lanxiu-aarch64-rootfs-20261017.tar.xz
  mkdir -p "$DEST" && cd "$DEST"
  echo "==> 下载 LANXIU 安卓版 rootfs（$TARBALL，约 88MB）"
  curl -fL --retry 5 --retry-delay 2 -C - -o "$TARBALL" "$BASE/$TARBALL"
  echo "==> 解包到 $DEST"
  tar -xJf "$TARBALL" && rm -f "$TARBALL"
elif [ "$1" = "--pkgs" ]; then
  shift
  DEST=${1:-$HOME/qyroot}
  shift 2>/dev/null || true
  PKGS="${*:-busybox-1.36.1-1.aarch64.qyp}"
  mkdir -p "$DEST" && cd "$DEST"
  for p in $PKGS; do
    echo "==> 下载 $p"
    # -f 失败即停；--retry 抗网络抖动；-C - 断点续传（不要并发跑同一文件）
    curl -fL --retry 5 --retry-delay 2 -C - -o "$p" "$BASE/$p"
    echo "==> 解包 $p"
    sh "$DIR/qyextract.sh" "$p" && rm -f "$p"
  done
else
  DEST=${1:-$HOME/qyroot}
  TARBALL=lanxiu-aarch64-rootfs-20261010.tar.xz
  mkdir -p "$DEST" && cd "$DEST"
  echo "==> 下载完整 rootfs（约 24MB）"
  curl -fL --retry 5 --retry-delay 2 -C - -o "$TARBALL" "$BASE/$TARBALL"
  echo "==> 解包到 $DEST"
  tar -xJf "$TARBALL" && rm -f "$TARBALL"
fi

echo "==> 完成。进入环境:"
echo "  proot -r $DEST -0 -b /dev -b /proc -b /sys /usr/bin/bash -l"