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
            groups: [
                "全部"
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