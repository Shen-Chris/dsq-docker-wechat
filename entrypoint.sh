#!/bin/sh

# root
if [ "$(id -u)" = '0' ]; then
    echo "Running as root, preparing environment..."

    # 尝试修复基础映射卷的权限
    chown -R 1000:1000 /home/headless || true
    chown -R 1000:1000 /wechat_data || true
    chown -R 1000:1000 /wechat_files || true
    chown -R 1000:1000 /headless/下载 || true
    echo "Permission fix attempt finished. Switching to user headless..."

    # headless
    exec gosu headless "$0" "$@"
fi

echo "Running as headless, setting up WeChat data links..."

mkdir -p "$HOME/.xwechat"

# 删除可能存在的旧数据目录（如果容器被重用）
#rm -rf "$HOME/.xwechat/All Users"
#rm -rf "$HOME/.xwechat/xwechat_files"

# 链接
# "$HOME/.xwechat/All Users" -> /wechat_data
# "$HOME/.xwechat/xwechat_files" -> /wechat_files
ln -s /wechat_data "$HOME/.xwechat/All Users"
ln -s /wechat_files "$HOME/.xwechat/xwechat_files"

echo "Symbolic links created. Handing over to the main container command..."

exec /dockerstartup/vnc_startup.sh --wait