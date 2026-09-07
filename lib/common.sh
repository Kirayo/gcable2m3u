#!/bin/sh

# 仅提供跨模块使用的基础辅助函数。
common_die() {
    log_error "$@"
    exit 1
}

common_require_command() {
    command -v "$1" >/dev/null 2>&1 || common_die "缺少命令: $1"
}

common_ensure_directory() {
    [ -d "$1" ] || mkdir -p "$1" || common_die "无法创建目录: $1"
}

common_trim() {
    value=$1
    value=${value%"${value##*[![:space:]]}"}
    value=${value#"${value%%[![:space:]]*}"}
    printf '%s' "$value"
}

common_is_empty() {
    [ -z "$(common_trim "$1")" ]
}

common_default() {
    if common_is_empty "$1"; then
        printf '%s' "$2"
    else
        printf '%s' "$1"
    fi
}

common_xml_escape() {
    printf '%s' "$1" | sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g' \
        -e 's/"/\&quot;/g' \
        -e "s/'/\&apos;/g"
}

log_emit() {
    printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$*" >&2
}

log_info() { log_emit INFO "$@"; }
log_warn() { log_emit WARN "$@"; }
log_error() { log_emit ERROR "$@"; }

http_get() {
    http_url=$1
    http_output=$2
    if ! command -v curl >/dev/null 2>&1; then
        log_error "未找到 curl"
        return 1
    fi
    curl -fsSL -o "$http_output" "$http_url"
}
