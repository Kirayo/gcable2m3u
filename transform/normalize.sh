#!/bin/sh

# ==============================================================================
# cable2m3u
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
#   6. 暂不生成业务分组
#
# 注意：
#   jq 可能未编译 Oniguruma，因此本脚本不使用：
#     match()
#     test()
#     sub()
#     gsub()
# ==============================================================================

channel_normalize() {
    records_file="$CHANNEL_DATA_FILE.records.$$"
    : > "$records_file" || return 1

    jq -c '
        [
            .channelGroups[]?
            | .channls[]?
        ]
        | reduce .[] as $channel
            ({};
                ($channel.channelID // "" | tostring) as $id
                | if $id == "" or has($id) then . else .[$id] = $channel end
            )
        | .[]
    ' "$CHANNEL_FILE" |
    while IFS= read -r channel; do
        [ -n "$channel" ] || continue

        printf '%s\n' "$channel" |
            channel_model_source |
            while IFS= read -r source; do
                [ -n "$source" ] || continue

                name=$(printf '%s\n' "$source" | jq -r '.name')
                source_id=$(printf '%s\n' "$source" | jq -r '.sourceId')
                channel_no=$(printf '%s\n' "$source" | jq -r '.channelNo')
                logo=$(printf '%s\n' "$source" | jq -r '.logo')
                service_type=$(printf '%s\n' "$source" | jq -r '.serviceType')

                channel=$(channel_model_create "$name" "$source_id" "$name" "$logo" "$channel_no" "$service_type")
                channel_model_add_source "$channel" "$source" >> "$records_file"
            done
    done || {
        rm -f "$records_file"
        return 1
    }

    channel_model_merge_records < "$records_file" > "$CHANNEL_DATA_FILE.$$" || {
        rm -f "$records_file" "$CHANNEL_DATA_FILE.$$"
        return 1
    }
    rm -f "$records_file"

    if [ ! -s "$CHANNEL_DATA_FILE.$$" ]; then
        rm -f "$CHANNEL_DATA_FILE.$$"
        echo "频道标准化结果为空" >&2
        return 1
    fi

    mv "$CHANNEL_DATA_FILE.$$" "$CHANNEL_DATA_FILE" || {
        rm -f "$CHANNEL_DATA_FILE.$$"
        return 1
    }
}