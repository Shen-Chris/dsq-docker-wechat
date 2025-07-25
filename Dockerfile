# 步骤1: 选择一个现代、被维护的VNC基础镜像 (docker镜像资源目前需要外网，国内的镜像待补充中，最好需要先单独自己docker pull consol/debian-xfce-vnc:latest)
FROM consol/debian-xfce-vnc:latest

# 步骤2: 切换到root用户以进行系统级安装
USER root

# 步骤3: 更换为国内镜像源以加速
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources

# 步骤4: 一次性安装所有依赖 (mousepad 用于测试)
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        mousepad \
        fonts-wqy-zenhei fonts-noto-cjk locales \
        libatomic1 libxkbcommon-x11-0 libxcb-xkb1 libxcb-icccm4 \
        libxcb-image0 libxcb-render-util0 libxcb-keysyms1 \
        fcitx5 fcitx5-chinese-addons fcitx5-frontend-gtk3 fcitx5-frontend-qt5 \
    && \
    sed -i -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 步骤5: 创建普通用户
# 明确创建可以确保UID/GID的统一性
RUN useradd -ms /bin/bash -u 1000 headless || true

# 步骤6: 为用户会话配置必要的环境变量
RUN echo '#!/bin/sh\nexport GTK_IM_MODULE=fcitx\nexport QT_IM_MODULE=fcitx\nexport XMODIFIERS=@im=fcitx' > /etc/profile.d/im-input.sh && \
    echo '#!/bin/sh\nif [ -z "$XDG_RUNTIME_DIR" ]; then\n    export XDG_RUNTIME_DIR=/run/user/$(id -u)\nfi' > /etc/profile.d/xdg-runtime-dir.sh && \
    chmod +x /etc/profile.d/*.sh

# 步骤7: 复制并安装微信 or 从构建参数指定的 URL 下载并安装微信
#本地镜像安装
#COPY weixin.deb /tmp/weixin.deb
#RUN apt-get update && apt-get install -y /tmp/weixin.deb && rm /tmp/weixin.deb
#下载安装
ARG WECHAT_URL
RUN apt-get update && apt-get install -y --no-install-recommends wget
RUN wget -O /tmp/weixin.deb "${WECHAT_URL}"
RUN apt-get install -y /tmp/weixin.deb && rm /tmp/weixin.deb

# 步骤8: 为 headless 用户创建程序自动启动和输入法配置文件
RUN mkdir -p /home/headless/.config/autostart /home/headless/.config/fcitx5 && \
    echo '[Desktop Entry]\nName=WeChat\nExec=/usr/bin/wechat --no-sandbox\nType=Application\nTerminal=false' > /home/headless/.config/autostart/wechat.desktop && \
    echo '[Desktop Entry]\nName=Fcitx5\nExec=dbus-launch fcitx5\nType=Application' > /home/headless/.config/autostart/fcitx5.desktop && \
    echo '[Profile]\nDefaultIM=classic\nIMList=keyboard-us,pinyin' > /home/headless/.config/fcitx5/profile

# 步骤9: 确保 headless 用户拥有其主目录的所有权
RUN chown -R headless:headless /home/headless

# 1. 创建一个在容器启动时创建目录的脚本
RUN echo '#!/bin/sh' > /usr/local/bin/create-runtime-dir.sh && \
    echo 'set -e' >> /usr/local/bin/create-runtime-dir.sh && \
    echo 'echo "[Init] Creating XDG_RUNTIME_DIR for user 1000..."' >> /usr/local/bin/create-runtime-dir.sh && \
    echo 'mkdir -p /run/user/1000' >> /usr/local/bin/create-runtime-dir.sh && \
    echo 'chown 1000:1000 /run/user/1000' >> /usr/local/bin/create-runtime-dir.sh && \
    echo 'chmod 0700 /run/user/1000' >> /usr/local/bin/create-runtime-dir.sh && \
    echo "[Init] Directory created successfully." >> /usr/local/bin/create-runtime-dir.sh && \
    chmod 755 /usr/local/bin/create-runtime-dir.sh

# 2. 创建一个 supervisord 配置文件，让它在启动VNC前，以root身份执行我们的脚本
# priority=1 确保它在所有其他服务（默认100）之前运行
RUN echo '[program:create-runtime-dir]' > /etc/supervisor/conf.d/create-runtime-dir.conf && \
    echo 'command=/usr/local/bin/create-runtime-dir.sh' >> /etc/supervisor/conf.d/create-runtime-dir.conf && \
    echo 'user=root' >> /etc/supervisor/conf.d/create-runtime-dir.conf && \
    echo 'autostart=true' >> /etc/supervisor/conf.d/create-runtime-dir.conf && \
    echo 'autorestart=false' >> /etc/supervisor/conf.d/create-runtime-dir.conf && \
    echo 'startsecs=0' >> /etc/supervisor/conf.d/create-runtime-dir.conf && \
    echo 'priority=1' >> /etc/supervisor/conf.d/create-runtime-dir.conf && \
    echo 'stdout_logfile=/dev/stdout' >> /etc/supervisor/conf.d/create-runtime-dir.conf && \
    echo 'stdout_logfile_maxbytes=0' >> /etc/supervisor/conf.d/create-runtime-dir.conf && \
    echo 'stderr_logfile=/dev/stderr' >> /etc/supervisor/conf.d/create-runtime-dir.conf && \
    echo 'stderr_logfile_maxbytes=0' >> /etc/supervisor/conf.d/create-runtime-dir.conf
