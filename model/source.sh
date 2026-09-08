#!/bin/sh

# ==============================================================================
# cable2m3u
# Source 数据模型
#
# Source 是一个实际播放源，对应广电 API 中的一条 channel 记录。
# 本文件只负责 API 频道到 Source 的转换，不负责请求、去重或输出。
# ==============================================================================

# 将广电 API 的频道记录转换成 Source 。
#
# 输入：jq 当前的 API channel 对象
# 输出：一个 Source JSON 对象
#
# 字段：
#   sourceId          API channelID
#   channelNo         API channelNumber
#   originalName      API channelName 原始频道名称
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
                {name: ($originalName[:-6]), quality: "高清特色"}
            elif ($originalName | endswith("（高清）")) then
                {name: ($originalName[:-4]), quality: "高清"}
            elif ($originalName | endswith("（标清）")) then
                {name: ($originalName[:-4]), quality: "标清"}
            elif ($originalName | endswith("（4K）")) then
                {name: ($originalName[:-4]), quality: "4K"}
            elif ($originalName | endswith("(高清特色)")) then
                {name: ($originalName[:-6]), quality: "高清特色"}
            elif ($originalName | endswith("(高清)")) then
                {name: ($originalName[:-4]), quality: "高清"}
            elif ($originalName | endswith("(标清)")) then
                {name: ($originalName[:-4]), quality: "标清"}
            elif ($originalName | endswith("(4K)")) then
                {name: ($originalName[:-4]), quality: "4K"}
            else
                {name: $originalName, quality: ""}
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
