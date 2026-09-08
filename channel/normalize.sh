#!/bin/sh

# ==============================================================================
# cabletv2m3u
# 频道标准化
#
# 输入：
#   $CHANNEL_FILE
#
# 输出：
#   $CHANNEL_DATA_FILE
#
# 处理：
#   1. 展开 API channelGroups
#   2. 按 channelID 去除 API 分组造成的重复
#   3. 拆分频道名称和清晰度
#   4. 保留播放地址
#   5. 保留 isTVAnyTime 回放标记
#
# 注意：
#   jq 可能未编译 Oniguruma，因此本脚本不使用：
#     match()
#     test()
#     sub()
#     gsub()
# ==============================================================================

channel_normalize() {
    jq -c '
        [
            .channelGroups[]?
            | .channls[]?
        ]
        | reduce .[] as $channel
            ({};
                ($channel.channelID // "") as $id
                | if $id == "" then
                    .
                  elif has($id) then
                    .
                  else
                    .[$id] = $channel
                  end
            )
        | .[]
        |
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
        (
            [
                .livePlayUrls[]?
                | select((.playUrl // "") != "")
                | {
                    playType: (.playType // ""),
                    playUrl: (.playUrl // "")
                }
            ]
        ) as $sources
        |
        {
            sourceId: (.channelID // ""),
            channelNo: (.channelNumber // ""),
            originalName: $originalName,
            name: $nameInfo.name,
            quality: $nameInfo.quality,

            serviceType: (.serviceType // ""),

            logo: (.imageUrl // ""),

            groupId: (.groupId // ""),

            isUnicast: (.isUnicast // "0"),
            isAuthentication: (.isAuthentication // "0"),

            bitRateType: (.bitRateType // ""),

            isTVAnyTime: (.isTVAnyTime // "0"),
            isStartOver: (.isStartOver // "0"),

            playUrl: ($sources[0].playUrl // ""),
            sources: $sources
        }
        | select(.sourceId != "")
    ' "$CHANNEL_FILE" > "$CHANNEL_DATA_FILE.tmp" || {
        rm -f "$CHANNEL_DATA_FILE.tmp"
        return 1
    }

    if [ ! -s "$CHANNEL_DATA_FILE.tmp" ]; then
        rm -f "$CHANNEL_DATA_FILE.tmp"
        echo "频道标准化结果为空" >&2
        return 1
    fi

    mv "$CHANNEL_DATA_FILE.tmp" "$CHANNEL_DATA_FILE"
}