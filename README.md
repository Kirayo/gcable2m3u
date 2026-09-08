# gcable2m3u

面向 OpenWrt 的 POSIX Shell 项目：从广东广电 API 获取频道列表并生成 M3U 播放列表。

## 目录结构

```text
gcable2m3u/
├── build.sh                    # 将源码合并为单文件分发脚本
├── main.sh                     # 源码入口
├── config.sh                   # 默认配置和本地配置加载
├── config.local.sh.example     # 设备配置模板
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

默认生成 `dist/gcable2m3u.sh`。也可以指定输出路径：

```sh
sh build.sh /tmp/gcable2m3u.sh
```

构建脚本会按固定顺序合并配置、模型、API、标准化和输出模块，并执行 Shell 语法检查。生成文件不再依赖源码目录，可以单独复制到 OpenWrt。

## OpenWrt 部署

最简单的部署只需要复制 `dist/gcable2m3u.sh`：

```sh
chmod 755 gcable2m3u.sh
./gcable2m3u.sh
```

脚本也可以从任意当前目录启动：

```sh
sh /root/gcable2m3u/main.sh
```

设备需要提供 POSIX `/bin/sh`、`curl` 和 `jq`。运行数据默认写入 `/tmp/cable2m3u`，M3U 和 EPG 软链接默认放在 `/www`。

## 配置

需要固定设备配置时，将 `config.local.sh.example` 复制为与脚本同目录的 `config.local.sh`：

```sh
cp config.local.sh.example config.local.sh
```

配置文件中使用以下形式，环境变量会优先：

```sh
API_CLIENT="${API_CLIENT:-your-client-id}"
```

配置优先级为：环境变量、同目录 `config.local.sh`、内置默认值。

常用变量包括 `API_NAVCHECK_URL`、`API_CHANNEL_URL`、`API_CLIENT`、`API_DEVICE_ID`、`RUNTIME_DIR`、`WEB_DIR`、`API_CONNECT_TIMEOUT`、`API_TIMEOUT` 和 `EPG_URL`。

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

## 当前范围

当前流程生成 M3U 播放列表。`epg.xml` 软链接作为后续 XMLTV 功能预留，当前不会生成节目单文件。

频道标准化结果会从 API 返回的 `livePlayUrls` 选择第一个有效播放地址，输出为顶层 `playUrl`；没有播放地址的频道不会写入 M3U。

## 开发验证

```sh
sh -n build.sh main.sh config.sh \
    api/client.sh transform/normalize.sh \
    model/source.sh model/channel.sh output/m3u.sh
sh build.sh
sh -n dist/gcable2m3u.sh
```
