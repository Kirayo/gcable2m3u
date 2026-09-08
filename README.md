# gcable2m3u

面向 OpenWrt 的 POSIX Shell 项目：支持从广东广电获取频道列表并生成 M3U 播放列表。

本项目采用 [MIT License](LICENSE)。

## 当前进度

当前流程生成 M3U 播放列表。`epg.xml` 软链接作为后续 XMLTV 功能预留，当前不会生成节目单文件。

## TODO

1. 完善频道分组和频道过滤规则。
2. 添加频道台标，并在 M3U 中输出 `tvg-logo`。
3. 使用广电 API 制作 EPG 节目单。
4. 添加时移和回放支持。

## 目录结构

```text
gcable2m3u/
├── build.sh                    # 将源码合并为单文件分发脚本
├── main.sh                     # 源码入口
├── config.sh                   # 默认配置和本地配置加载
├── gcable2m3u.config           # 设备配置模板
├── api/client.sh               # API 请求和响应检查
├── transform/normalize.sh      # 频道数据标准化
├── model/source.sh             # Source 数据模型
├── model/channel.sh            # Channel 聚合模型
├── output/m3u.sh               # M3U 输出
└── dist/gcable2m3u.sh          # build.sh 生成的分发文件
```

`dist/` 是构建产物目录，不应提交设备配置、API 响应或运行时文件。

## 构建单文件

在源码根目录执行：

```sh
sh build.sh
```

默认生成 `dist/gcable2m3u.sh` 和 `dist/gcable2m3u.config`。也可以指定输出脚本路径，配置文件会输出到同一目录：

```sh
sh build.sh /tmp/gcable2m3u.sh
# 输出：/tmp/gcable2m3u.sh
#       /tmp/gcable2m3u.config
```

构建脚本会按固定顺序合并配置、模型、API、标准化和输出模块，并执行 Shell 语法检查，同时复制配置模板。生成的脚本和配置文件可以一起复制到 OpenWrt。

## OpenWrt 部署

最简单的部署是复制 `dist/` 下的脚本和配置模板：

```sh
cp dist/gcable2m3u.sh dist/gcable2m3u.config /root/
chmod 755 gcable2m3u.sh
./gcable2m3u.sh
```

脚本也可以从任意当前目录启动：

```sh
sh /root/gcable2m3u/main.sh
```

设备需要提供 POSIX `/bin/sh`、`curl` 和 `jq`。运行数据默认写入 `/tmp/cable2m3u`，M3U 和 EPG 文件以软链接形式放在 `/www`，实现局域网分发。

## 配置

将 `gcable2m3u.config` 放在与脚本同目录：

```sh
cp gcable2m3u.config /root/gcable2m3u/gcable2m3u.config
```

配置文件中使用以下形式，环境变量会优先：

```sh
API_CLIENT="${API_CLIENT:-[your-client-id]}"
替换 [your-client-id]
```

`API_CLIENT` 一般为智能卡号或登录号，没有内置默认值，请到机顶盒设置页面获取。配置优先级为：环境变量、同目录 `gcable2m3u.config`。

常用变量包括 `API_CLIENT`、`API_DEVICE_ID`、`RUNTIME_DIR`、`WEB_DIR`、`API_CONNECT_TIMEOUT`、`API_TIMEOUT` 和 `EPG_URL`。

运行日志同时输出到终端和 OpenWrt 系统日志，默认标签为 `gcable2m3u`，可通过 `LOG_TAG` 修改。使用 `logread -t gcable2m3u` 查看。

也可以直接使用环境变量：

```sh
API_CLIENT="your-client-id" \
RUNTIME_DIR=/tmp/cable2m3u \
WEB_DIR=/www \
sh /root/gcable2m3u/main.sh
```

## 定时运行

cron 使用入口脚本的绝对路径

示例：

```cron
*/30 * * * * /root/gcable2m3u.sh >/dev/null 2>&1
```
