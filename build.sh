#!/bin/sh

# 将多文件源码合并为可独立分发的单文件脚本。

set -e

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OUTPUT_FILE=${1:-$PROJECT_DIR/dist/get_iptv.sh}
OUTPUT_DIR=$(dirname -- "$OUTPUT_FILE")
TEMP_FILE="$OUTPUT_FILE.tmp.$$"

cleanup() {
    rm -f "$TEMP_FILE"
}

trap cleanup EXIT HUP INT TERM

mkdir -p "$OUTPUT_DIR"

for source_file in \
    "$PROJECT_DIR/config.sh" \
    "$PROJECT_DIR/model/channel.sh" \
    "$PROJECT_DIR/api/data.sh" \
    "$PROJECT_DIR/channel/normalize.sh" \
    "$PROJECT_DIR/output/m3u.sh"; do
    [ -f "$source_file" ] || {
        echo "缺少构建输入: $source_file" >&2
        exit 1
    }
done

{
    printf '%s\n' '#!/bin/sh'
    printf '%s\n' 'PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)'
    printf '\n'

    sed '1{/^#!\/bin\/sh$/d;}' "$PROJECT_DIR/config.sh"
    sed '1{/^#!\/bin\/sh$/d;}' "$PROJECT_DIR/model/channel.sh"
    printf '\n'
    sed '1{/^#!\/bin\/sh$/d;}' "$PROJECT_DIR/api/data.sh"
    printf '\n'
    sed '1{/^#!\/bin\/sh$/d;}' "$PROJECT_DIR/channel/normalize.sh"
    printf '\n'
    sed '1{/^#!\/bin\/sh$/d;}' "$PROJECT_DIR/output/m3u.sh"
    printf '\n'

    awk '
        /^# BEGIN RUNTIME$/ { in_runtime = 1 }
        in_runtime { print }
    ' "$PROJECT_DIR/get_iptv.sh" | sed '/^main "\$@"$/d'

    printf '%s\n' 'main "$@"'
} > "$TEMP_FILE"

shebang_count=$(grep -c '^#!' "$TEMP_FILE" || true)
[ "$shebang_count" -eq 1 ] || {
    echo "构建产物 shebang 数量错误: $shebang_count" >&2
    exit 1
}

grep -q '\. "\$PROJECT_DIR/' "$TEMP_FILE" && {
    echo "构建产物仍包含源码模块加载路径" >&2
    exit 1
}

main_count=$(grep -c '^main "\$@"$' "$TEMP_FILE" || true)
[ "$main_count" -eq 1 ] || {
    echo "构建产物入口数量错误: $main_count" >&2
    exit 1
}

sh -n "$TEMP_FILE" || {
    echo "构建产物语法检查失败" >&2
    exit 1
}

mv "$TEMP_FILE" "$OUTPUT_FILE"
chmod 755 "$OUTPUT_FILE"
trap - EXIT HUP INT TERM

echo "构建完成: $OUTPUT_FILE"