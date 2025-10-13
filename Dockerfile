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
        gosu wget sudo \
        mousepad \
        # --- 基础字体与环境 ---
        fonts-wqy-zenhei fonts-noto-cjk fonts-noto-color-emoji locales \
        # --- 微信运行时库 (ldd分析得出) ---
        libatomic1 libxkbcommon-x11-0 libxcb-xkb1 libxcb-icccm4 \
        libxcb-image0 libxcb-render-util0 libxcb-keysyms1 \
        # --- 中文输入法框架和引擎 (Fcitx5) -
        im-config \
        fcitx5 fcitx5-chinese-addons fcitx5-material-color fcitx5-frontend-gtk3 fcitx5-frontend-qt5 \
        # ---音频 ---
        pulseaudio pulseaudio-utils \
    && \
    # 配置中文环境
    sed -i -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    # 清理
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 创建普通用户
RUN useradd -ms /bin/bash -u 1000 headless || true
# 配置sudo，授予headless用户免密权限
RUN echo 'headless ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/headless-nopasswd

# 下载并安装微信
RUN echo "Downloading from: ${WECHAT_URL}" && \
    wget -O /tmp/weixin.deb "${WECHAT_URL}" && \
    apt-get update && \
    apt-get install -y /tmp/weixin.deb && \
    rm /tmp/weixin.deb

# 环境变量
RUN echo '#!/bin/sh\n\
export LANG="zh_CN.UTF-8"\n\
export LC_ALL="zh_CN.UTF-8"\n\
export GTK_IM_MODULE="fcitx"\n\
export QT_IM_MODULE="fcitx"\n\
export XMODIFIERS="@im=fcitx"' > /etc/X11/Xsession.d/99-custom-im-env && \
    chmod +x /etc/X11/Xsession.d/99-custom-im-env

# im-config 官方方式配置输入法
# RUN im-config -n fcitx5

# 配置VNC核心启动脚本
RUN mkdir -p /home/headless/.vnc
COPY xstartup /home/headless/.vnc/xstartup
RUN chmod +x /home/headless/.vnc/xstartup

# 复制音频自启动脚本
COPY pulse-autostart.sh /usr/local/bin/pulse-autostart.sh
RUN chmod +x /usr/local/bin/pulse-autostart.sh

# 为 headless 用户创建所有自动启动项
RUN mkdir -p /home/headless/.config/autostart && \
    echo '[Desktop Entry]\nName=WeChat\nExec=/usr/bin/wechat --no-sandbox\nType=Application' > /home/headless/.config/autostart/wechat.desktop && \
    echo '[Desktop Entry]\nName=Fcitx5\nExec=fcitx5\nType=Application' > /home/headless/.config/autostart/fcitx5.desktop && \
    echo '[Desktop Entry]\nName=PulseAudio\nExec=/usr/local/bin/pulse-autostart.sh\nType=Application' > /home/headless/.config/autostart/pulseaudio.desktop

# Fcitx5配置
COPY fcitx5_profile /headless/.config/fcitx5/profile
# 权限
RUN chown -R 1000:1000 /home/headless/.config/autostart /headless/.config/fcitx5/profile

# 加入音频相关的组
RUN usermod -a -G audio,pulse-access headless

# 集成权限修复脚本
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 设置入口点
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/dockerstartup/vnc_startup.sh", "--wait"]