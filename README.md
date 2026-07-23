# dsq-docker-wechat/qq/telegram+
在docker linux系统里运行wechat，可以通过web或者VNC访问wechat，可扩展安装QQ/Telegram 等linux软件 (`sudo dpkg -i **.deb`),
使用 [consol/debian-xfce-vnc:latest](https://hub.docker.com/r/consol/debian-xfce-vnc) 和 微信官方linux x86版本https://linux.weixin.qq.com/ 构建而来，自带fcitx5中文输入法，更多详情配置参考官方

- debian-xfce-vnc
- 微信官方linux x86版本 （其他版本暂未构建，有需要可以自己尝试打包）
- fcitx5中文输入法

调试不易，希望点点小🌟🌟，谢谢

## v1.1 新功能 / 修复
- emoji ✅
- headless用户sudo权限 ✅
- 官方微信包语音视频通话卡住异常 (疑似和声音设备有关) ✅
- vnc复制粘贴中文不兼容  ing （孩子没招了）
- 微信映射文件持久化存储  ❓✅ ([容器配置](https://github.com/Shen-Chris/dsq-docker-wechat/tree/main?tab=readme-ov-file#2docker-composeyml)：1-[直接映射](https://github.com/Shen-Chris/dsq-docker-wechat/issues/4#issuecomment-3247910819);  2-[间接修改](https://github.com/Shen-Chris/dsq-docker-wechat/tree/main?tab=readme-ov-file#1%E5%AE%B9%E5%99%A8%E9%85%8D%E7%BD%AE-%E5%BE%AE%E4%BF%A1%E6%8C%81%E4%B9%85%E5%8C%96%E5%AD%98%E5%82%A8)-需要首次赋予目录权限后手动修改微信存储目录)
- 待补充

# beta版本
  雾凇输入法初始化脚本
```
# 1. 装工具
sudo apt-get update && sudo apt-get install -y git unzip fcitx5-rime fcitx5-config-qt
# 2. 开代理下载可加快  需要在bashrc 配置代理 
cd ~ && wget -O rime-ice.zip https://github.com/iDvel/rime-ice/archive/refs/heads/main.zip && unzip rime-ice.zip && mv rime-ice-main rime-ice && mkdir -p ~/.local/share/fcitx5/rime && cp -r rime-ice/* ~/.local/share/fcitx5/rime/ && rm -rf rime-ice rime-ice.zip
# 3. 激活重启 然后在运行脚本理找到 fcitx5配置，第一次可能会有问题再打开一次就行，到最下面找到【中州语】选择到左边最上面优先级即可
sudo -u headless bash -c 'im-config -n fcitx5; pkill -9 fcitx5 2>/dev/null; fcitx5 -d'
```
- [v1.2](https://github.com/Shen-Chris/dsq-docker-wechat/tree/v1.2?tab=readme-ov-file#v12-%E6%96%B0%E5%8A%9F%E8%83%BD--%E4%BF%AE%E5%A4%8D)

# 自构建镜像
linux环境下，拉取本项目，执行buildImagesLocal.sh 脚本 (`chmod +x buildImagesLocal.sh`)

# 启动

## 1、拉取
```
稳定版本
docker pull ghcr.io/shen-chris/dsq-docker-wechat:main

迭代版本:
docker pull ghcr.io/shen-chris/dsq-docker-wechat:v1.1

测试版本：
docker pull ghcr.io/shen-chris/dsq-docker-wechat:v1.2  # 构建中ing
```

## 2、docker-compose.yml
路径、密码请自定义
```yml
services:
  wechat:
    # 镜像
    image: ghcr.io/shen-chris/dsq-docker-wechat:main
    container_name: dsq-docker-wechat
    hostname: wechat
    ports:
      - "6901:6901"  # Web访问端口
      - "5901:5901"  # VNC客户端访问端口
    user: "1000:1000" # 以 UID 1000 和 GID 1000 的身份运行 即 headless用户
    volumes:
      # 挂载数据卷，实现数据持久化，路径请自定义
      #- "/path/xwechat:/headless/.xwechat"  # 直接映射微信存储目录
      #- "/path/xwechat_files:/headless/文档/xwechat_files" # 直接映射微信存储目录
      - "/path/wechat_data:/wechat_data" # 间接修改微信存储目录
      - "/path/wechat_files:/wechat_files" # 间接修改微信存储目录
      - "/path/downloads:/headless/下载" # 通用
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
1. ssh隧道，单端口 ``` ssh -L 5901:localhost:5901 用户@ip或域名 [-p ssh端口] ``` eg. ```ssh -o ServerAliveInterval=60 -L 5901:localhost:5901 root@www.ssq.cn -p 22``` 连接后不要断开，ServerAliveInterval=60，60秒“心跳包”按需增删，打开vnc客户端连接localhost:5901 ；```ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -L 5901:localhost:5901 root@www.ssq.cn -p 22 -N```ServerAliveCountMax断开重试次数，-N只转发不执行命令（不会进入远程终端）
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
## 1.容器配置-微信持久化存储
#### 间接修改微信存储目录
[docker-compose.yml配置](https://github.com/Shen-Chris/dsq-docker-wechat/tree/main?tab=readme-ov-file#2docker-composeyml)里映射的持久化目录为/wechat_data，登录微信后在左下角 **设置-账号与存储-存储位置** 点击更改按钮修改成持久化目录（例如/wechat_data/xwechat_files），若权限不足更改失败，需要首次修改权限（！仅供参考！）后再更改（首次启动容器首次登录微信需要修改存储目录）
```shell
# ！仅供参考以实际为主！
sudo chown -R headless:headless /wechat_data /wechat_files
sudo chmod 755 /wechat_data /wechat_files
```
#### 直接映射（可能出问题）
[参考直接映射](https://github.com/Shen-Chris/dsq-docker-wechat/issues/4#issuecomment-3247910819)

## 2.fcitx5输入法 [**已默认配置中文输入法，ctrl space切换输入法**]
若输入法存在问题（例如部分程序无法使用），则需要修改环境变量后重新启动容器:
修改环境变量```vim ~/.bashrc```，在末尾添加
```bashrc
export LANG="zh_CN.UTF-8"
export LC_ALL="zh_CN.UTF-8"
export GTK_IM_MODULE="fcitx"
export QT_IM_MODULE="fcitx"
export XMODIFIERS="@im=fcitx"
```
再生效```source ~/.bashrc``` 后
如若未生效则需要重新启动容器后，再启动fcitx5尝试

## 3、wechat版本升级可选方法
1、流水线[每月1号自动构建更新](https://github.com/Shen-Chris/dsq-docker-wechat/blob/main/.github/workflows/docker-publish.yml)  
2、[自构建镜像](https://github.com/Shen-Chris/dsq-docker-wechat?tab=readme-ov-file#%E8%87%AA%E6%9E%84%E5%BB%BA%E9%95%9C%E5%83%8F) ，每次构建都会下载最新的官方安装包  
3、headless有sudo权限，可以自定义安装  
```
wget https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb
sudo dpkg -i WeChatLinux_x86_64.deb
# 安装后打不开则是需要重启容器 docker restart <容器ID或名称>
```
4、fork我的仓库，利用github流水线构建镜像  


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



