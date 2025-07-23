# 步骤1: VNC基础镜像
FROM consol/debian-xfce-vnc:latest

# 步骤2: 切换到root用户以进行软件安装
USER root

# 步骤3: 更换为国内镜像源以加速
RUN sed -i 's/deb.debian.org/mirrors.aliyun.com/g' /etc/apt/sources.list.d/debian.sources

# 步骤4: 安装所有已知依赖（最关键的一步，调试了好久好久😅无语亖了）
RUN \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        ca-certificates \
        fonts-wqy-zenhei \
        fonts-noto-cjk \
        libatomic1 \
        libxkbcommon-x11-0 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-render-util0 \
        libxcb-keysyms1 \
        locales && \
    \
    # 生成中文语言包
    sed -i -e 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen && \
    \
    # 清理工作，保持镜像精简
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 步骤5: 将宿主机上下载好的安装包复制到镜像的/tmp/目录下
COPY weixin.deb /tmp/weixin.deb

# 步骤6: 使用apt直接安装本地deb包，它会自动处理剩余依赖
RUN apt-get update && \
    apt-get install -y /tmp/weixin.deb && \
    rm /tmp/weixin.deb

# 步骤7: 为微信创建一个自动启动项
RUN mkdir -p /home/headless/.config/autostart && \
    echo '[Desktop Entry]\n\
Name=WeChat\n\
Exec=/usr/bin/wechat --no-sandbox\n\
Type=Application\n\
Terminal=false' > /home/headless/.config/autostart/wechat.desktop && \
    chown -R 1000:1000 /home/headless/.config
