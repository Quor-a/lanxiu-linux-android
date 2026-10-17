#!/bin/sh
# 解包 LANXIU .qyp 包（安卓/Termux 环境，仅依赖 busybox 的 od/tail/tar）
#
# .qyp 不是普通 tar 容器：文件头 128 字节（"QYPKG" 魔数 + 元数据偏移表），
# 数据段从 data_off 开始，是 **gzip 压缩的 tar**（不是 zstd）。
# 直接 `tar -xf` 会因头部 128 字节垃圾报 "bad checksum"。
#
# 用法: qyextract.sh <包.qyp> [目标目录]
set -e
PKG=$1
DEST=${2:-.}
[ -f "$PKG" ] || { echo "找不到包: $PKG" >&2; exit 1; }

# 校验魔数
magic=$(od -An -tx1 -N5 "$PKG" | tr -d ' \n')
[ "$magic" = "5159504b47" ] || { echo "不是有效的 qyp 包: $PKG" >&2; exit 1; }

# 读 data_off：头布局 <8s I I Q Q Q Q Q Q 32s 32s (小端)
# data_off 在字节偏移 32，8 字节小端 u64
off=$(od -An -tu8 -j32 -N8 --endian=little "$PKG" | tr -d ' ')
[ -n "$off" ] || { echo "无法解析 data_off" >&2; exit 1; }

# 完整性：文件必须覆盖整个数据段（下载截断的包会在这里报错）
# data_off 位于偏移 32，data_len 位于偏移 40
dlen=$(od -An -tu8 -j40 -N8 --endian=little "$PKG" | tr -d ' ')
size=$(wc -c < "$PKG")
[ "$size" -ge $((off + dlen)) ] || {
  echo "包不完整：文件 $size 字节，但数据段需要 $((off + dlen)) 字节（下载截断？请重新下载）" >&2
  exit 1
}

echo "==> 解包 $PKG（数据段偏移 $off）到 $DEST"
mkdir -p "$DEST"
tail -c +$((off + 1)) "$PKG" | tar -xz -C "$DEST"
echo "==> 完成"
