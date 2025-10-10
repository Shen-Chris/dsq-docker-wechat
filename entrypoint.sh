#!/bin/sh

# --- root修复权限 ---
if [ "$(id -u)" = '0' ]; then
    echo "Running as root, attempting to fix permissions..."
    chown -R 1000:1000 /home/headless || true
    chown -R 1000:1000 /headless/.xwechat || true
    chown -R 1000:1000 /headless/文档/xwechat_files || true
    chown -R 1000:1000 /headless/下载 || true
    echo "Permission fix attempt finished. Switching to user headless..."

    # 切换到 headless 用户
    exec gosu headless "$0" "$@"
fi

echo "Running as headless, handing over to the base image's main command..."

exec /bin/bash /dockerstartup/vnc_startup.sh --wait