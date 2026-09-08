#!/bin/sh

# ==============================================================================
# 广电 IPTV API
# ============================================================================

# ------------------------------------------------------------------------------
# NavCheck
# ------------------------------------------------------------------------------

api_navcheck() {
    navcheck_url="${API_NAVCHECK_URL}?client=${API_CLIENT}&deviceId=${API_DEVICE_ID}&resultType=json"

    curl -fsS \
        --connect-timeout "$API_CONNECT_TIMEOUT" \
        --max-time "$API_TIMEOUT" \
        -o "$NAVCHECK_FILE.$$" \
        "$navcheck_url" || {
        rm -f "$NAVCHECK_FILE.$$"
        return 1
    }

    # API 请求成功后再替换正式文件。
    mv "$NAVCHECK_FILE.$$" "$NAVCHECK_FILE"
}

# ------------------------------------------------------------------------------
# 获取 account
# ------------------------------------------------------------------------------

api_get_account() {
    jq -r '.account // empty' "$NAVCHECK_FILE"
}

# ------------------------------------------------------------------------------
# 获取频道
# ------------------------------------------------------------------------------

api_get_channels() {
    account=$1

    [ -n "$account" ] || {
        echo "account 为空，无法获取频道列表" >&2
        return 1
    }

    channel_url="${API_CHANNEL_URL}?account=${account}&type=1&includeChannel=Y"

    curl -fsS \
        --connect-timeout "$API_CONNECT_TIMEOUT" \
        --max-time "$API_TIMEOUT" \
        -o "$CHANNEL_FILE.$$" \
        "$channel_url" || {
        rm -f "$CHANNEL_FILE.$$"
        return 1
    }

    # API 请求成功后再替换正式文件。
    mv "$CHANNEL_FILE.$$" "$CHANNEL_FILE"
}

# ------------------------------------------------------------------------------
# 检查 JSON
# ------------------------------------------------------------------------------

api_check_json() {
    file=$1

    [ -s "$file" ] || {
        echo "API 返回为空: $file" >&2
        return 1
    }

    jq empty "$file" >/dev/null 2>&1 || {
        echo "API 返回无效 JSON: $file" >&2
        return 1
    }
}

# ------------------------------------------------------------------------------
# 检查频道数据
# ------------------------------------------------------------------------------

api_check_channels() {
    # 确认存在 channelGroups。
    jq -e '
        (.channelGroups? | type == "array")
    ' "$CHANNEL_FILE" >/dev/null 2>&1 || {
        echo "频道 API 数据缺少 channelGroups" >&2
        return 1
    }

    # 确认至少存在一个频道。
    channel_count=$(jq '
        [
            .channelGroups[]?.channls[]?
        ] | length
    ' "$CHANNEL_FILE")

    [ "$channel_count" -gt 0 ] || {
        echo "频道列表为空" >&2
        return 1
    }

    echo "$channel_count"
}