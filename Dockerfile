
ARG WECHAT_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb"

# 基础镜像
FROM consol/debian-xfce-vnc:latest

# ----------------------------------
LABEL org.opencontainers.image.description="dsq-docker-wechat v1.1 版本更新\n\
- 主要新增: sudo \n\
- 发布于: 2025.8.14\n\
\n\
测试版本，有问题请提交(issue)[https://github.com/Shen-Chris/dsq-docker-wechat]"
# ----------------------------------

# 切换到 root 用户进行系统级安装
USER root

ARG WECHAT_URL

# 更换为国内镜像源以加速
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources

# 安装所有依赖
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    # --- 核心工具 ---
    sudo \
    # --- 基础字体与环境 ---
    fonts-wqy-zenhei \
    fonts-noto-cjk \
    fonts-noto-color-emoji \
    locales \
    # --- 微信运行时库 (ldd分析得出) ---
    libatomic1 \
    libxkbcommon-x11-0 \
    libxcb-xkb1 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-render-util0 \
    libxcb-keysyms1 \
    # --- 中文输入法框架和引擎 (Fcitx5) ---
    fcitx5 \
    fcitx5-chinese-addons \
    fcitx5-frontend-gtk3 \
    fcitx5-frontend-qt5 \
    # --- 剪贴板兼容性工具 ---
    autocutsel \
    # --- PulseAudio 音频客户端库 ---
    pulseaudio \
    wget \
    && sed -i -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# 创建普通用户
RUN useradd -ms /bin/bash -u 1000 headless || true
# 配置sudo，授予headless用户免密权限
RUN echo 'headless ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/headless-nopasswd

RUN echo "Downloading from: ${WECHAT_URL}" && \
    wget -O /tmp/weixin.deb "${WECHAT_URL}"

# 安装下载好的 .deb 文件，并清理
RUN apt-get install -y /tmp/weixin.deb && rm /tmp/weixin.deb

# 为用户会话配置必要的环境变量
RUN echo '#!/bin/sh\nexport GTK_IM_MODULE=fcitx\nexport QT_IM_MODULE=fcitx\nexport XMODIFIERS=@im=fcitx' > /etc/profile.d/im-input.sh && \
    echo '#!/bin/sh\nif [ -z "$XDG_RUNTIME_DIR" ]; then\n    export XDG_RUNTIME_DIR=/run/user/$(id -u)\nfi' > /etc/profile.d/xdg-runtime-dir.sh && \
    chmod +x /etc/profile.d/*.sh

# 为 headless 用户创建程序自动启动和输入法配置文件 + 剪切板同步
RUN mkdir -p /home/headless/.config/autostart /home/headless/.config/fcitx5 && \
    echo '[Desktop Entry]\nName=WeChat\nExec=/usr/bin/wechat --no-sandbox\nType=Application\nTerminal=false' > /home/headless/.config/autostart/wechat.desktop && \
    echo '[Desktop Entry]\nName=Fcitx5\nExec=dbus-launch fcitx5\nType=Application' > /home/headless/.config/autostart/fcitx5.desktop && \
    echo '[Profile]\nDefaultIM=classic\nIMList=keyboard-us,pinyin' > /home/headless/.config/fcitx5/profile && \
    # 启动剪贴板同步器
    echo '[Desktop Entry]\nName=Autocutsel\nExec=autocutsel -fork\nType=Application' > /home/headless/.config/autostart/autocutsel.desktop

# 确保 headless 用户拥有其主目录的所有权
RUN chown -R headless:headless /home/headless

# 将headless用户加入音频相关的组 ---
RUN usermod -a -G pulse-access headless

# 创建 supervisord 任务以解决权限问题
RUN echo '#!/bin/sh\nset -e\necho "[Init] Creating XDG_RUNTIME_DIR for user 1000..."\nmkdir -p /run/user/1000\nchown 1000:1000 /run/user/1000\nchmod 0700 /run/user/1000\necho "[Init] Directory created successfully."' > /usr/local/bin/create-runtime-dir.sh && \
    chmod 755 /usr/local/bin/create-runtime-dir.sh

RUN echo '[program:create-runtime-dir]\ncommand=/usr/local/bin/create-runtime-dir.sh\nuser=root\nautostart=true\nautorestart=false\nstartsecs=0\npriority=1\nstdout_logfile=/dev/stdout\nstdout_logfile_maxbytes=0\nstderr_logfile=/dev/stderr\nstderr_logfile_maxbytes=0' > /etc/supervisor/conf.d/create-runtime-dir.conf

# ---集成权限修复脚本 ---
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]