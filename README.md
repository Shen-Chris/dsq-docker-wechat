# docker-wechat-vnc
在docker里运行wechat，可以通过web或者VNC访问wechat
使用 [consol/debian-xfce-vnc:latest](https://hub.docker.com/r/consol/debian-xfce-vnc) 和 微信官方linux x86版本https://linux.weixin.qq.com/ 构建而来，更多详情配置参考官方

调试不易，希望点点小心心，谢谢

# docker-compose.yml
```yml
services:
  wechat:
    # 这里使用您刚刚构建的镜像！
    image: my-wechat:latest
    container_name: my-wechat
    ports:
      - "6901:6901"  # Web访问端口
      - "5901:5901"  # VNC客户端访问端口
    volumes:
      # 挂载数据卷，实现数据持久化，路径请自定义
      - "/path/data:/home/headless/.config/weixin"
      - "/path/files:/home/headless/WeChat_files"
    environment:
      # --- 在这里添加或修改分辨率 ---
      - "VNC_RESOLUTION=1366x768"
      - "LANG=zh_CN.UTF-8"
      - "LANGUAGE=zh_CN:zh"
      - "LC_ALL=zh_CN.UTF-8"
      - "TZ=Asia/Shanghai"
      - "VNC_PW=dsqpwd" # 设置您自己的VNC连接密码
    # 调整共享内存大小，新版微信可能需要
    shm_size: '4068m'
```
docker-compose up -d 启动即可
