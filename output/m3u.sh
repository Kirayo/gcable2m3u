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
# 生成 M3U
# ------------------------------------------------------------------------------

m3u_generate() {
    m3u_write_header

    jq -r '
                (.tvgId // "") as $tvgId
                | (.channelNo // "") as $channelNo
                | (.name // "") as $name
                | (.logo // "") as $logo
                | ((.groups // [])[0] // "") as $group
                | .sources[]?
                | (.serviceType // "") as $serviceType
                | (.quality // "") as $quality
                | (.playUrl // "") as $sourceUrl
                | select($name != "" and $sourceUrl != "")
                | (if $quality != "" then $sourceUrl + "$" + $quality else $sourceUrl end) as $playUrl
        | "#EXTINF:-1"
                    + (if $tvgId != "" then " tvg-id=\"" + $tvgId + "\"" else "" end)
          + (if $channelNo != "" then " tvg-chno=\"" + $channelNo + "\"" else "" end)
          + " tvg-name=\"" + $name + "\""
          + (if $serviceType == "2" then " radio=\"true\"" else "" end)
          + (if $logo != "" then " tvg-logo=\"" + $logo + "\"" else "" end)
                    + (if $group != "" then " group-title=\"" + $group + "\"" else "" end)
          + "," + $name + "\n" + $playUrl
    ' "$CHANNEL_DATA_FILE"
}