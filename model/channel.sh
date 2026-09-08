#!/bin/sh

# ==============================================================================
# cabletv2m3u
# Channel 数据模型
#
# Channel
#   一个逻辑频道，可以包含多个不同清晰度/线路的 Source。
#
# Source
#   一个实际播放源，对应广电 API 中的一条 channel 记录。
#
# 注意：
#   本文件只负责数据模型，不负责：
#   - API 请求
#   - 频道分类
#   - 去重
#   - M3U 输出
# ==============================================================================


# ==============================================================================
# Source 模型
# ==============================================================================

# 将广电 API 的频道记录转换成 Source。
#
# 输入：
#   jq 当前的 API channel 对象
#
# 输出：
#   一个 Source JSON 对象
#
# 字段：
#   sourceId          API channelID
#   channelNo         API channelNumber
#   originalName      API 原始频道名称
#   name              去除清晰度后的频道名称
#   quality           清晰度
#   serviceType       服务类型
#   logo              Logo
#   playType          播放类型
#   playUrl           播放地址
#   isTVAnyTime       是否支持回放
#   isUnicast         是否单播
#   isAuthentication  是否需要认证
#   bitRateType       码率类型
#   isStartOver       API 原始字段
#
channel_model_source() {
    jq '
        (
            .channelName // ""
        ) as $originalName

        |

        (
            if ($originalName | endswith("（高清特色）")) then
                {
                    name: ($originalName[:-6]),
                    quality: "高清特色"
                }
            elif ($originalName | endswith("（高清）")) then
                {
                    name: ($originalName[:-4]),
                    quality: "高清"
                }
            elif ($originalName | endswith("（标清）")) then
                {
                    name: ($originalName[:-4]),
                    quality: "标清"
                }
            elif ($originalName | endswith("（4K）")) then
                {
                    name: ($originalName[:-4]),
                    quality: "4K"
                }
            elif ($originalName | endswith("(高清特色)")) then
                {
                    name: ($originalName[:-6]),
                    quality: "高清特色"
                }
            elif ($originalName | endswith("(高清)")) then
                {
                    name: ($originalName[:-4]),
                    quality: "高清"
                }
            elif ($originalName | endswith("(标清)")) then
                {
                    name: ($originalName[:-4]),
                    quality: "标清"
                }
            elif ($originalName | endswith("(4K)")) then
                {
                    name: ($originalName[:-4]),
                    quality: "4K"
                }
            else
                {
                    name: $originalName,
                    quality: ""
                }
            end
        ) as $nameInfo

        |

        {
            sourceId: (.channelID // ""),
            channelNo: (.channelNumber // ""),

            originalName: $originalName,
            name: $nameInfo.name,
            quality: $nameInfo.quality,

            serviceType: (.serviceType // ""),

            logo: (.imageUrl // ""),

            isUnicast: (.isUnicast // "0"),
            isAuthentication: (.isAuthentication // "0"),

            bitRateType: (.bitRateType // ""),

            isTVAnyTime: (.isTVAnyTime // "0"),
            isStartOver: (.isStartOver // "0"),

            sources: [
                .livePlayUrls[]?
                | select((.playUrl // "") != "")
                | {
                    playType: (.playType // ""),
                    playUrl: (.playUrl // "")
                }
            ]
        }

        | select(.sourceId != "")
    '
}


# ==============================================================================
# Channel 模型
# ==============================================================================

# 创建一个空的逻辑频道。
#
# 参数：
#   $1 = logicalId
#   $2 = tvgId
#   $3 = name
#   $4 = logo
#   $5 = channelNo
#   $6 = serviceType
#
channel_model_create() {
    jq -n \
        --arg id "$1" \
        --arg tvg_id "$2" \
        --arg name "$3" \
        --arg logo "$4" \
        --arg channel_no "$5" \
        --arg service_type "$6" \
        '{
            id: $id,
            tvgId: $tvg_id,
            name: $name,
            logo: $logo,
            channelNo: $channel_no,
            serviceType: $service_type,
            groups: [
                "全部频道"
            ],
            sources: []
        }'
}


# ==============================================================================
# Channel 添加 Source
# ==============================================================================

# 将 Source 添加到 Channel。
#
# 用法：
#
#   channel=$(channel_model_create ...)
#   source=$(...)
#   channel=$(channel_model_add_source "$channel" "$source")
#
channel_model_add_source() {
    channel="$1"
    source="$2"

    printf '%s\n' "$channel" |
        jq --argjson source "$source" '
            .sources += [$source]
        '
}


# ==============================================================================
# Channel 添加分组
# ==============================================================================

# 给 Channel 添加业务分组。
#
# “全部频道”始终保留。
#
channel_model_add_group() {
    channel="$1"
    group="$2"

    [ -n "$group" ] || {
        printf '%s\n' "$channel"
        return 0
    }

    printf '%s\n' "$channel" |
        jq --arg group "$group" '
            if (.groups | index($group)) then
                .
            else
                .groups += [$group]
            end
        '
}