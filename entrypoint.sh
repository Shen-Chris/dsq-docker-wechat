#!/bin/sh
# 权限修复和交接

# root用户
if [ "$(id -u)" = '0' ]; then
    echo "Running as root, attempting to fix permissions..."
    chown -R 1000:1000 /home/headless || true
    chown -R 1000:1000 /headless/.xwechat || true
    chown -R 1000:1000 /headless/文档/xwechat_files || true
    chown -R 1000:1000 /headless/下载 || true
    echo "Permission fix attempt finished. Switching to user headless..."

    # 切换到 headless
    exec gosu headless "$0" "$@"
fi

echo "Running as headless, handing over to the main container command..."

exec "$@"