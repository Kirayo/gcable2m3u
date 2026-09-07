# 广电 API → M3U + XMLTV

这是一个面向 OpenWrt 的 POSIX Shell 项目：从广电 API 获取频道和节目数据，经过标准化、过滤、排序、分组与映射后，输出 M3U 播放列表和 XMLTV 节目单。

## 当前阶段

当前已实现输入文件链路、频道/节目中间格式、频道处理、XMLTV 映射、M3U/XMLTV 基础输出，以及基于 `curl` 的 HTTP 下载边界。仍不假设广电 API 的 URL、认证方式、JSON 字段或响应结构，API 原始响应的字段解析留待下一阶段。

## 目录结构

```text
cabletv2m3u/
├── get_iptv.sh          # 主入口：加载配置、库和模块，串联后续流程
├── config/
│   ├── config.sh        # 运行配置与默认值
│   └── epg-map.conf     # 频道到 XMLTV 标识的映射配置
├── api/
│   └── data.sh          # API 获取、解析和标准模型转换
├── output/
│   └── output.sh        # M3U 和 XMLTV 输出
└── lib/
  └── common.sh        # 日志、HTTP、目录和 XML 辅助函数
```

## 数据流

```text
配置
  ↓
API Client / Parser
  ↓
Standard Model
  ↓
频道标准化 → 过滤 → 排序 → 分组 ─┐
                                   ├→ M3U
节目标准化 → 合并 → 标识映射 ─────┘
                                   └→ XMLTV
```

各模块通过 Shell 函数和约定的数据文件衔接。当前中间文件使用 `|` 分隔，每行一个频道或节目；字段值不能包含 `|`。引入 JSON 解析实现时，应优先使用 OpenWrt 中可用的轻量工具，并把 API 字段差异限制在 `api/` 与标准化模块内。

## 入口加载顺序

`get_iptv.sh` 按以下顺序加载：配置 → 公共库 → 数据处理 → 输出。数据处理模块内部完成 API Client、Parser、Standard Model 和两条 Pipeline；输出模块完成 M3U/XMLTV Renderer。

未配置 API URL 时，可通过 `CABLETV2M3U_CHANNEL_SOURCE` 与 `CABLETV2M3U_EPG_SOURCE` 指定符合中间格式的本地文件；两者都未指定时会生成示例数据，便于验证输出链路。

## 后续实现顺序

1. 根据实际接口补充认证、请求头、分页和 JSON 字段提取。
2. 为频道和节目输入增加真实 API 样本及异常响应处理。
3. 完善时间格式、时区、节目去重和跨天节目处理。
4. 根据实际需求再拆分频道或 EPG 处理模块。
5. 为输出增加原子写入、备份和失败恢复。
6. 在 OpenWrt/BusyBox ash 上做端到端验证，并补充定时任务示例。

## 兼容性约束

脚本使用 POSIX Shell 语法，目标解释器为 `/bin/sh`。不使用 Bash 数组、`[[ ... ]]`、进程替换、`${BASH_SOURCE[0]}` 或 Bash 专属参数扩展。

## 使用方式

```sh
chmod +x get_iptv.sh
./get_iptv.sh
```

指定真实接口时，例如：

```sh
CABLETV2M3U_CHANNEL_API_URL="https://example.invalid/channels" \
CABLETV2M3U_EPG_API_URL="https://example.invalid/epg" \
./get_iptv.sh
```

输出默认写入 `output-data/playlist.m3u` 和 `output-data/epg.xml`。
