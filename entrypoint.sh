#!/bin/sh

# --- headless 权限修复 ---
echo "Fixing permissions for mapped volumes..."
chown -R 1000:1000 /headless/.xwechat
chown -R 1000:1000 /headless/文档/xwechat_files
chown -R 1000:1000 /headless/下载
echo "Permissions fixed."


exec "$@"