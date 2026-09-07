#!/bin/sh

# ==============================================================================
# 频道标准化
# ==============================================================================

channel_normalize() {
    jq -c '
        .channelGroups[]?
        | .channls[]?
        | {
            sourceId: (.channelID // ""),
            channelNo: (.channelNumber // ""),
            originalName: (.channelName // ""),

            name: (
                (.channelName // "")
                | sub("^(CCTV-[0-9]+)([^ ])"; "\\1 \\2")
                | sub("（高清）$"; "")
            ),

            logo: (.imageUrl // ""),
            sourceGroupId: (.groupId // ""),

            playUrls: [
                .livePlayUrls[]?
                | {
                    playType: (.playType // ""),
                    playUrl: (.playUrl // "")
                }
                | select(.playUrl != "")
            ],

            playUrl: (
                [
                    .livePlayUrls[]?
                    | select(.playType == "2")
                    | .playUrl
                ][0] // ""
            )
        }

        | select(.sourceId != "")
    ' "$CHANNEL_FILE" > "$CHANNEL_DATA_FILE.tmp" || {
        rm -f "$CHANNEL_DATA_FILE.tmp"
        return 1
    }

    # 确保标准化结果不是空文件。
    [ -s "$CHANNEL_DATA_FILE.tmp" ] || {
        echo "频道标准化结果为空" >&2
        rm -f "$CHANNEL_DATA_FILE.tmp"
        return 1
    }

    # 原子替换。
    mv "$CHANNEL_DATA_FILE.tmp" "$CHANNEL_DATA_FILE"
}