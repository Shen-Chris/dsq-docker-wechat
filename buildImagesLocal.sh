# 先把微信linux x86安装包下载到本地，和Dockerfile同级目录
weget https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb -O weixin.deb

# 开始构建
docker build --no-cache -t dsq-docker-wechat:latest --build-arg WECHAT_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb" .
