#!/bin/sh

# ==============================================================================
# M3U 输出
# ==============================================================================

# ------------------------------------------------------------------------------
# M3U Header
# ------------------------------------------------------------------------------

m3u_write_header() {
    if [ -n "$EPG_URL" ]; then
        printf '#EXTM3U url-tvg="%s"\n' "$EPG_URL"
    else
        printf '#EXTM3U\n'
    fi
}

# ------------------------------------------------------------------------------
# 输出单个频道
# ------------------------------------------------------------------------------

m3u_write_channel() {
    channel=$1

    source_id=$(printf '%s' "$channel" | jq -r '.sourceId // ""')
    channel_no=$(printf '%s' "$channel" | jq -r '.channelNo // ""')
    name=$(printf '%s' "$channel" | jq -r '.name // ""')
    logo=$(printf '%s' "$channel" | jq -r '.logo // ""')
    play_url=$(printf '%s' "$channel" | jq -r '.playUrl // ""')

    # 当前还没有正式的频道分类模块。
    group="其他"

    # 没有播放地址的频道暂时不输出。
    [ -n "$play_url" ] || return 0

    # 没有名称也没有必要输出。
    [ -n "$name" ] || return 0

    printf '#EXTINF:-1'

    # tvg-id 使用广电 channelID。
    [ -n "$source_id" ] &&
        printf ' tvg-id="%s"' "$source_id"

    # 频道号。
    [ -n "$channel_no" ] &&
        printf ' tvg-chno="%s"' "$channel_no"

    # XMLTV / M3U 频道名称。
    [ -n "$name" ] &&
        printf ' tvg-name="%s"' "$name"

    # API 有 Logo 时才输出。
    [ -n "$logo" ] &&
        printf ' tvg-logo="%s"' "$logo"

    # 当前统一归类到其他。
    printf ' group-title="%s"' "$group"

    # 显示名称。
    printf ',%s\n' "$name"

    # 播放地址。
    printf '%s\n' "$play_url"
}

# ------------------------------------------------------------------------------
# 生成 M3U
# ------------------------------------------------------------------------------

m3u_generate() {
    m3u_write_header

    while IFS= read -r channel; do
        [ -n "$channel" ] || continue

        m3u_write_channel "$channel"
    done < "$CHANNEL_DATA_FILE"
}