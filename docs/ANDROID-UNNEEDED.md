# 安卓（proot/chroot）不需要的包统计

> 统计基于 `Quor-a/qiyuan-linux-aarch64` Release 的 `index.json`（117 个包）。
> 判定标准：LANXIU 安卓版走 **proot/chroot** 落地，不使用原生显示服务器/内核引导，
> 因此以下包在安卓场景下用不到。移除可再瘦身约 **60MB**。

## 一、完全不需要（9 个，约 26.3MB）

| 包 | 大小 | 说明 |
|---|---|---|
| `kernel-arm64` | 17.1MB | Linux 内核（arm64）。仅「路径 C 原生刷机」需要，proot/chroot 用不到 |
| `glslang` | 3.5MB | GLSL 着色器编译器。mesa 构建期依赖，运行时不需要 |
| `weston` | 3.3MB | Wayland 参考合成器。安卓 proot 里没有 Wayland 会话，用不到 |
| `linux-headers` | 1.5MB | Linux 内核用户空间头文件。开发用，运行时不需要 |
| `libinput` | 1.1MB | 输入设备处理库。仅原生显示服务器需要 |
| `libevdev` | 126KB | 输入事件设备封装库。仅原生显示服务器需要 |
| `seatd` | 80KB | seat/会话管理守护进程。weston 依赖 |
| `mtdev` | 22KB | 多点触控协议转换库。仅原生显示服务器需要 |
| `libqydemo` | 4KB | 启元演示共享库。qydesktop 不依赖它 |

## 二、头文件包（运行时不需要，13 个，约 1MB）

`compositeproto` `damageproto` `fixesproto` `inputproto` `kbproto` `randrproto`
`renderproto` `xcb-proto` `xextproto` `xineramaproto` `xorg-macros` `xorgproto` `xtrans`

这些是 X11 协议/构建宏头文件，仅在编译期需要，运行时无二进制。

## 三、可选（4 个，约 32.7MB，按需保留）

| 包 | 大小 | 说明 |
|---|---|---|
| `mesa` | 32.2MB | OpenGL/Vulkan 实现。GTK 在 X11 转发下可纯软件渲染（cairo），但保留可硬件加速 |
| `libdrm` | 646KB | DRM 内核接口。mesa 依赖，纯软件渲染不需要 |
| `wayland` | 451KB | Wayland 显示协议。若走 Wayland 后端（而非 X11）才需要 |
| `wayland-protocols` | 223KB | Wayland 标准扩展协议集合。同上 |

## 结论

- **建议从 rootfs/仓库剔除**：第一类 9 个（省 ~26MB）+ 第二类 13 个头文件包（省 ~1MB）。
- **默认保留**：第三类（mesa/wayland 等），避免影响未来在安卓上跑 Wayland 桌面/GPU 渲染。
- 剔除后 rootfs 预计可再瘦身 ~27MB（压缩后影响更小）。

## 生成方式

```sh
curl -L -o index.json https://github.com/Quor-a/qiyuan-linux-aarch64/releases/download/latest/index.json
python3 - <<'PY'
import json
d=json.load(open('index.json'))
for p in d['packages']:
    print(p['name'], p['size'], p['summary'])
PY
```