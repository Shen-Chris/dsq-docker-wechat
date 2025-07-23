# dsq-docker-wechat
在docker里运行wechat，可以通过web或者VNC访问wechat  
使用 [consol/debian-xfce-vnc:latest](https://hub.docker.com/r/consol/debian-xfce-vnc) 和 微信官方linux x86版本https://linux.weixin.qq.com/ 构建而来，更多详情配置参考官方

调试不易，希望点点小心心，谢谢


# 构建
linux环境下，拉取本项目，执行buildImagesLocal.sh 脚本 (`chmod +x buildImagesLocal.sh`)

# 启动
本构建资源待上传中，请稍等
## docker-compose.yml
```yml
services:
  wechat:
    # 这里使用您刚刚构建的镜像！
    image: dsq-docker-wechat:latest
    container_name: dsq-docker-wechat
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

# 效果
vnc预览效果
<img width="1920" height="1015" alt="image" src="https://github.com/user-attachments/assets/56b7a8a8-5b2c-46dd-82db-bef70cfdd7aa" />

<img width="1920" height="1019" alt="image" src="https://github.com/user-attachments/assets/fd5324fd-b8c3-4568-9b16-7a9b57b4e95b" />

<img width="1920" height="1016" alt="image" src="https://github.com/user-attachments/assets/e632f491-c595-4ee4-9bf7-8d33268ac6a1" />

<img width="1364" height="806" alt="image" src="https://github.com/user-attachments/assets/f6b9f484-2bb4-4a50-a942-63ebd244245e" />

浏览器预览效果
<img width="1920" height="944" alt="image" src="https://github.com/user-attachments/assets/1b90f90d-5573-40a3-9b54-1a8710699337" />




