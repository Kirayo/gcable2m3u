#!/bin/sh

# ==============================================================================
# cable2m3u
#
# 广电 IPTV API → M3U
#
# 执行：
#   sh main.sh
#
# Cron：
#   */30 * * * * /root/gcable2m3u/main.sh >/dev/null 2>&1
#
# ==============================================================================

# ==============================================================================
# 项目目录
# ==============================================================================

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# ==============================================================================
# 加载配置
# ==============================================================================

. "$PROJECT_DIR/config.sh"

# ==============================================================================
# 加载模块
# ==============================================================================

. "$PROJECT_DIR/model/source.sh"
. "$PROJECT_DIR/model/channel.sh"
. "$PROJECT_DIR/api/client.sh"
. "$PROJECT_DIR/transform/normalize.sh"
. "$PROJECT_DIR/output/m3u.sh"

# BEGIN RUNTIME

# 同时输出终端和 OpenWrt 系统日志；没有 logger 时不影响主流程。
log_info() {
    printf '%s\n' "$*"
    command -v logger >/dev/null 2>&1 && logger -t "$LOG_TAG" -- "$*"
}

log_error() {
    printf '%s\n' "$*" >&2
    command -v logger >/dev/null 2>&1 && logger -t "$LOG_TAG" -p user.err -- "$*"
}

# ==============================================================================
# 初始化
# ==============================================================================

init_runtime() {
    mkdir -p "$RUNTIME_DIR" || {
        log_error "无法创建运行目录: $RUNTIME_DIR"
        return 1
    }

    mkdir -p "$WEB_DIR" || {
        log_error "无法创建 Web 目录: $WEB_DIR"
        return 1
    }
}

# ==============================================================================
# 检查依赖
# ==============================================================================

check_dependencies() {
    [ -n "$API_CLIENT" ] || {
        log_error "未配置 API_CLIENT，请在 gcable2m3u.config 或 环境变量中设置"
        return 1
    }

    command -v curl >/dev/null 2>&1 || {
        log_error "缺少依赖: curl"
        return 1
    }

    command -v jq >/dev/null 2>&1 || {
        log_error "缺少依赖: jq"
        return 1
    }
}

# ==============================================================================
# Web 软链接
# ==============================================================================

ensure_web_link() {
    link_path=$1
    target_path=$2

    if [ -e "$link_path" ] && [ ! -L "$link_path" ]; then
        log_error "Web 路径已存在但不是软链接: $link_path"
        return 1
    fi

    if [ -L "$link_path" ]; then
        [ "$(readlink "$link_path")" = "$target_path" ] && [ -e "$link_path" ] && return 0
        rm -f "$link_path" || {
            log_error "无法移除失效 Web 软链接: $link_path"
            return 1
        }
    fi

    ln -s "$target_path" "$link_path" || {
        log_error "创建 Web 软链接失败: $link_path"
        return 1
    }
}

setup_web_links() {
    ensure_web_link "$WEB_DIR/iptv.m3u" "$M3U_FILE" || return 1
    ensure_web_link "$WEB_DIR/epg.xml" "$EPG_FILE" || return 1
}

# ==============================================================================
# 生成 M3U
# ==============================================================================

generate_m3u() {
    log_info "正在生成 M3U..."

    # 先写临时文件。
    m3u_temp_file="$M3U_TEMP_FILE.$$"

    m3u_generate > "$m3u_temp_file" || {
        log_error "M3U 生成失败"
        rm -f "$m3u_temp_file"
        return 1
    }

    # 至少应该包含 #EXTM3U。
    [ -s "$m3u_temp_file" ] || {
        log_error "M3U 文件为空"
        rm -f "$m3u_temp_file"
        return 1
    }

    # 至少存在一个频道。
    m3u_channel_count=$(grep -c '^#EXTINF:' "$m3u_temp_file")

    [ "$m3u_channel_count" -gt 0 ] || {
        log_error "M3U 没有有效频道"
        rm -f "$m3u_temp_file"
        return 1
    }

    # 原子替换正式文件。
    mv "$m3u_temp_file" "$M3U_FILE" || {
        log_error "无法替换 M3U 文件"
        rm -f "$m3u_temp_file"
        return 1
    }

    log_info "M3U 频道数量: $m3u_channel_count"
}

# ==============================================================================
# 主流程
# ==============================================================================

main() {
    log_info "========================================"
    log_info " cable2m3u"
    log_info "========================================"

    # --------------------------------------------------------------------------
    # 初始化
    # --------------------------------------------------------------------------

    init_runtime || exit 1
    check_dependencies || exit 1
    setup_web_links || exit 1

    # --------------------------------------------------------------------------
    # NavCheck
    # --------------------------------------------------------------------------

    log_info "正在执行 NavCheck..."

    api_navcheck || {
        log_error "NavCheck 请求失败"
        exit 1
    }

    api_check_json "$NAVCHECK_FILE" || exit 1

    # --------------------------------------------------------------------------
    # 获取 account
    # --------------------------------------------------------------------------

    account=$(api_get_account)

    [ -n "$account" ] || {
        log_error "NavCheck 未返回 account"
        exit 1
    }

    log_info "Account: $account"

    # --------------------------------------------------------------------------
    # 获取频道
    # --------------------------------------------------------------------------

    log_info "正在获取频道列表..."

    api_get_channels "$account" || {
        log_error "GetGroupChannels 请求失败"
        exit 1
    }

    api_check_json "$CHANNEL_FILE" || exit 1

    channel_count=$(api_check_channels) || exit 1

    log_info "API 频道数量: $channel_count"

    # --------------------------------------------------------------------------
    # 标准化
    # --------------------------------------------------------------------------

    log_info "正在标准化频道..."

    channel_normalize || {
        log_error "频道标准化失败"
        exit 1
    }

    normalized_count=$(wc -l < "$CHANNEL_DATA_FILE")

    log_info "标准化频道数量: $normalized_count"

    [ "$normalized_count" -gt 0 ] || {
        log_error "标准化后没有频道"
        exit 1
    }

    # --------------------------------------------------------------------------
    # M3U
    # --------------------------------------------------------------------------

    generate_m3u || exit 1

    # --------------------------------------------------------------------------
    # 完成
    # --------------------------------------------------------------------------

    log_info "----------------------------------------"
    log_info "生成完成:"
    log_info "  M3U : $M3U_FILE"
    log_info "  Web : $WEB_DIR/iptv.m3u"
    log_info "----------------------------------------"
}

# ==============================================================================
# END RUNTIME
# ==============================================================================

main "$@"