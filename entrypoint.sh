#!/bin/sh

# --- headless 权限修复 ---
echo "Fixing permissions for mapped volumes..."
chown -R 1000:1000 /headless/.xwechat
chown -R 1000:1000 /headless/文档/xwechat_files
chown -R 1000:1000 /headless/下载
echo "Permissions fixed."

# --- 容器内的、带“假声卡”的PulseAudio服务 ---
echo "Starting container-local PulseAudio server with a null sink..."
# 以守护进程模式启动，并且永不因空闲而退出
pulseaudio -D --exit-idle-time=-1

# 加载“黑洞”模块，创建一个名为"dummy_sink"的假输出设备
pactl load-module module-null-sink sink_name=dummy_sink

# 将这个假设备设置为默认输出
pactl set-default-sink dummy_sink

# （可选）创建一个假的输入设备（麦克风）
pactl load-module module-null-sink sink_name=dummy_source media.class=Audio/Source/Virtual
pactl set-default-source dummy_source
echo "PulseAudio with null sink is ready."

exec "$@"