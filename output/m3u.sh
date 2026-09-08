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

    printf '%s' "$channel" | jq -r '
        (.sourceId // "") as $sourceId
        | (.channelNo // "") as $channelNo
        | (.name // "") as $name
        | (.logo // "") as $logo
        | (.playUrl // "") as $playUrl
        | select($name != "" and $playUrl != "")
        | "#EXTINF:-1"
          + (if $sourceId != "" then " tvg-id=\"" + $sourceId + "\"" else "" end)
          + (if $channelNo != "" then " tvg-chno=\"" + $channelNo + "\"" else "" end)
          + " tvg-name=\"" + $name + "\""
          + (if $logo != "" then " tvg-logo=\"" + $logo + "\"" else "" end)
          + " group-title=\"其他\""
          + "," + $name + "\n" + $playUrl
    '
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