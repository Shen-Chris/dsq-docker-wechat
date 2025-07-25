#!/bin/sh
set -e

IMAGE_NAME="dsq-docker-wechat"
IMAGE_TAG="latest"

# 微信安装包的下载地址
WECHAT_DOWNLOAD_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb"

# 1. 下载微信安装包到本地，命名为 weixin.deb
echo "================================================="
echo "Downloading WeChat package from ${WECHAT_DOWNLOAD_URL}"
echo "================================================="
wget "${WECHAT_DOWNLOAD_URL}" -O weixin.deb

# 2
echo "================================================="
echo "Starting Docker build for ${IMAGE_NAME}:${IMAGE_TAG}"
echo "================================================="
docker build --no-cache \
  -t "${IMAGE_NAME}:${IMAGE_TAG}" \
  --build-arg "WECHAT_URL=${WECHAT_DOWNLOAD_URL}" \
  .

echo "================================================="
echo "Build complete. Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "================================================="
