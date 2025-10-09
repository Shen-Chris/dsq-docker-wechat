#!/bin/sh

# --- 步骤1: 以root身份运行，尝试修复权限 ---
if [ "$(id -u)" = '0' ]; then
    echo "Running as root, attempting to fix permissions..."
    chown -R 1000:1000 /headless/.xwechat || true
    chown -R 1000:1000 /headless/文档/xwechat_files || true
    chown -R 1000:1000 /headless/下载 || true
    echo "Permission fix attempt finished."

    # 将控制权交给 headless 用户
    exec gosu headless "$0" "$@"
fi

# --- 步骤2: 创建一个D-Bus会话，并在其中运行所有后续服务 ---

echo "Running as headless, launching main process inside a DBus session..."

# 使用 dbus-run-session 来创建一个包含D-Bus环境的子shell。
exec dbus-run-session -- sh -c '
    echo "Inside DBus session, starting PulseAudio..."
    # 启动PulseAudio服务
    pulseaudio -D --exit-idle-time=-1

    echo "Waiting for PulseAudio to initialize..."
    sleep 2

    # 检查PulseAudio服务是否真的在运行
    if pgrep -u headless pulseaudio > /dev/null; then
        echo "PulseAudio process found. Configuring null sink..."
        # 配置虚拟声卡
        pactl load-module module-null-sink sink_name=dummy_sink
        pactl set-default-sink dummy_sink
        pactl load-module module-null-sink sink_name=dummy_source media.class=Audio/Source/Virtual
        pactl set-default-source dummy_source
        echo "PulseAudio configured successfully."
    else
        echo "ERROR: PulseAudio process did not start. Audio will not work."
    fi

    echo "Executing original container command..."
    # 执行传递给容器的原始命令，通常是 /usr/bin/vnc.sh
    exec "$@"
'