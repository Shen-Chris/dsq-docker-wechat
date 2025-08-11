# dsq-docker-wechat
在docker里运行wechat，可以通过web或者VNC访问wechat  
使用 [consol/debian-xfce-vnc:latest](https://hub.docker.com/r/consol/debian-xfce-vnc) 和 微信官方linux x86版本https://linux.weixin.qq.com/ 构建而来，自带fcitx5中文输入法，更多详情配置参考官方

- debian-xfce-vnc
- 微信官方linux x86版本 （其他版本暂未构建，有需要可以自己尝试打包）
- fcitx5中文输入法

调试不易，希望点点小🌟🌟，谢谢

# 自构建镜像
linux环境下，拉取本项目，执行buildImagesLocal.sh 脚本 (`chmod +x buildImagesLocal.sh`)

# 启动

## 1、拉取
```
docker pull ghcr.io/shen-chris/dsq-docker-wechat:main
```

## 2、docker-compose.yml
路径、密码请自定义
```yml
services:
  wechat:
    # 镜像
    image: ghcr.io/shen-chris/dsq-docker-wechat:main
    container_name: dsq-docker-wechat
    ports:
      - "6901:6901"  # Web访问端口
      - "5901:5901"  # VNC客户端访问端口
    user: "1000:1000" # 以 UID 1000 和 GID 1000 的身份运行 即 headless用户
    volumes:
      # 挂载数据卷，实现数据持久化，路径请自定义
      - "/path/data:/home/headless/.config/weixin"
      - "/path/files:/home/headless/WeChat_files"
    environment:
      # --- 分辨率 ---
      - "VNC_RESOLUTION=1366x768"
      - "LANG=zh_CN.UTF-8"
      - "LANGUAGE=zh_CN:zh"
      - "LC_ALL=zh_CN.UTF-8"
      - "TZ=Asia/Shanghai"
      - "VNC_PW=dsqpwd" # VNC连接密码
    # 调整共享内存大小，新版微信可能需要
    shm_size: '4068m'
```
## 3、启动
docker-compose up -d 启动即可

## 4、安全性配置
### vnc
建议不要把内网5901端口直接暴露到外网，会有风险，可以考虑以下几种方式转发
1. ssh隧道，单端口 ``` ssh -L 5901:localhost:5901 用户@ip或域名 [-p ssh端口] ``` eg. ```ssh -o ServerAliveInterval=60 -L 5901:localhost:5901 root@www.ssq.cn -p 22``` 连接后不要断开，ServerAliveInterval=60，60秒“心跳包”按需增删，打开vnc客户端连接localhost:5901
> 问题：~$ channel 3: open failed: administratively prohibited: open failed 是SSH配置策略明确禁止了这个转发行为，sudo vim /etc/ssh/sshd_config，```Match User root
    AllowTcpForwarding yes```
2. VPN
3. stunnel
### novnc
反向代理https，http有风险，示例
```
server {
    listen 6901 ssl http2 ;
    listen [::]:6901 ssl http2 ;

    server_name www.ssq.cn;
    index index.php index.html index.htm default.php default.htm default.html;
    root /www/wwwroot/www.ssq.cn;

    #SSL-START SSL相关配置，请勿删除或修改下一行带注释的404规则
    #error_page 404/404.html;
    #ssl_certificate    /xxx/fullchain.pem;
    #ssl_certificate_key    /xxx/privkey.pem;
    #ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;
    # 证书配置省略。。。

    location ^~ / {     
      proxy_pass http://192.168.1.23:6901; # !!!! 修改成自己docker 服务内网能访问的ip !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      proxy_set_header Host $http_host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Real-Port $remote_port;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_set_header X-Forwarded-Host $host;
      proxy_set_header X-Forwarded-Port $server_port;
      proxy_set_header REMOTE-HOST $remote_addr;
      
      proxy_connect_timeout 60s;
      proxy_send_timeout 600s;
      proxy_read_timeout 600s;
      proxy_http_version 1.1;  # 支持websocket !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection $connection_upgrade;
    }
    
    #PROXY-CONF-END
    #SERVER-BLOCK END

    #禁止访问的文件或目录
    location ~ ^/(\.user.ini|\.htaccess|\.git|\.env|\.svn|\.project|LICENSE|README.md)
    {
        return 404;
    }

    #一键申请SSL证书验证目录相关设置
    location /.well-known{
        allow all;
    }

    #禁止在证书验证目录放入敏感文件
    if ( $uri ~ "^/\.well-known/.*\.(php|jsp|py|js|css|lua|ts|go|zip|tar\.gz|rar|7z|sql|bak)$" ) {
        return 403;
    }

    #LOG START
access_log  /www/wwwlogs/www.ssq.cn.log;
    error_log  /www/wwwlogs/www.ssq.cn.error.log;
    #LOG END
}
```

# 其他问题
1. fcitx5默认用中文输入法，打开运行程序，下拉，点击fcitx5配置，打开profile文件修改成：
```
[Groups/0]
# Group Name
Name=中文输入
# Layout
Default Layout=cn
# Default Input Method
DefaultIM=pinyin

[Groups/0/Items/0]
# Name
Name=keyboard-us
# Layout
Layout=

[Groups/0/Items/1]
# Name
Name=pinyin
# Layout=
Layout=

[GroupOrder]
0=中文输入
```

# 预览效果
vnc预览效果
<img width="1920" height="1015" alt="image" src="https://github.com/user-attachments/assets/56b7a8a8-5b2c-46dd-82db-bef70cfdd7aa" />

<img width="1920" height="1019" alt="image" src="https://github.com/user-attachments/assets/fd5324fd-b8c3-4568-9b16-7a9b57b4e95b" />

<img width="1920" height="1016" alt="image" src="https://github.com/user-attachments/assets/e632f491-c595-4ee4-9bf7-8d33268ac6a1" />

<img width="1364" height="806" alt="image" src="https://github.com/user-attachments/assets/f6b9f484-2bb4-4a50-a942-63ebd244245e" />

浏览器预览效果
<img width="1920" height="944" alt="image" src="https://github.com/user-attachments/assets/1b90f90d-5573-40a3-9b54-1a8710699337" />

中文输入法效果预览
<img width="1920" height="1022" alt="image" src="https://github.com/user-attachments/assets/f012ff8f-f011-434e-a662-abb4e80448bf" />



