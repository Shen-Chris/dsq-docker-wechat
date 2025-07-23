# 先把微信linux x86安装包下载到本地，和Dockerfile同级目录
weget https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb -O weixin.deb

# 构建
docker build --no-cache -t dsq-docker-wechat:latest --build-arg HTTP_PROXY="http://192.168.1.254:7890" --build-arg HTTPS_PROXY="http://192.168.1.254:7890" --build-arg WECHAT_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb" .
