#!/bin/sh

# ==============================================================================
# cable2m3u
# Channel 数据模型
#
# Channel 是一个逻辑频道，可以包含多个不同清晰度或线路的 Source。
# 本文件只负责逻辑频道聚合，不负责 Source 转换、API 请求、去重或 M3U 输出。
# ==============================================================================

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
            groups: [],
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

# 将同一逻辑频道的中间记录聚合为一个 Channel。
channel_model_merge_records() {
    jq -c -s '
        reduce .[] as $record
            ({order: [], channels: {}};
                if .channels | has($record.id) then
                    .channels[$record.id].sources += $record.sources
                else
                    .order += [$record.id]
                    | .channels[$record.id] = $record
                end
            )
                | [.order[] as $id
                        | .channels[$id]
                        | .sources |= (
                            unique_by([.playUrl, .playType, .quality])
                            | sort_by(
                                (if .quality == "4K" then 0
                                 elif .quality == "高清" then 1
                                 else 2
                                 end),
                                .quality,
                                .playType,
                                .playUrl
                            )
                        )
                        | .groups = []
                    ]
                | sort_by((.channelNo | tonumber?) // 999999, .name)
                | to_entries[] as $entry
                | $entry.value + {
                        channelNo: (($entry.key + 1) | tostring)
                }
    '
}


# ==============================================================================
# Channel 添加分组
# ==============================================================================

# 给 Channel 添加业务分组。
#
# “全部”分组始终保留。
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