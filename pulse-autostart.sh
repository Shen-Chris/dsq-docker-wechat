#!/bin/sh
# 这个脚本将在XFCE桌面会话启动时自动运行， 此时，D-Bus等所有环境都已准备就绪

pulseaudio -D --exit-idle-time=-1

# 等待 确保服务就绪
sleep 2

# 配置虚拟声卡
pactl load-module module-null-sink sink_name=dummy_sink
pactl set-default-sink dummy_sink
pactl load-module module-null-sink sink_name=dummy_source media.class=Audio/Source/Virtual
pactl set-default-source dummy_source