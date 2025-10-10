#!/bin/sh
# 权限修复脚本

# 以root身份运行，尝试修复权限
if [ "$(id -u)" = '0' ]; then
    echo "Running as root, attempting to fix permissions..."
    chown -R 1000:1000 /headless/.xwechat || true
    chown -R 1000:1000 /headless/文档/xwechat_files || true
    chown -R 1000:1000 /headless/下载 || true
    echo "Permission fix attempt finished."

    # headless
    exec gosu headless "$0" "$@"
fi

exec "$@"