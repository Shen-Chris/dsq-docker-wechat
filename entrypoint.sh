#!/bin/sh

# --- 步骤1: 以root身份运行，尝试修复权限 ---
if [ "$(id -u)" = '0' ]; then
    echo "Running as root, attempting to fix permissions..."
    # 尝试修复权限，失败继续执行
    chown -R 1000:1000 /headless/.xwechat || true
    chown -R 1000:1000 /headless/文档/xwechat_files || true
    chown -R 1000:1000 /headless/下载 || true
    echo "Permission fix attempt finished."

    # 以 headless 用户的身份，重新执行本脚本，并传递所有参数，这样后续的所有操作都将在正确的低权限用户下运行
    exec gosu headless "$0" "$@"
fi

# --- 从这里开始，脚本将以 headless 用户的身份运行 ---

# --- 步骤2: 启动并配置PulseAudio ---
echo "Running as $(whoami), starting container-local PulseAudio..."
# 守护进程模式
pulseaudio -D --exit-idle-time=-1

# 等待2秒，确保PulseAudio服务已完全准备就绪
echo "Waiting for PulseAudio to initialize..."
sleep 2

# 加载“黑洞”模块，创建虚拟声卡
pactl load-module module-null-sink sink_name=dummy_sink
pactl set-default-sink dummy_sink
pactl load-module module-null-sink sink_name=dummy_source media.class=Audio/Source/Virtual
pactl set-default-source dummy_source
echo "PulseAudio with null sink is ready."

# --- 步骤3 ---
# 启动VNC和其他桌面服务
echo "Handing over to the main container command..."
exec "$@"