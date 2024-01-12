#!/bin/bash

# 确保脚本以 root 权限运行
if [ "$EUID" -ne 0 ]
  then echo "请以 root 权限运行此脚本"
  exit
fi

# 更新软件包和系统
echo "正在更新软件包和系统..."
apt update && apt upgrade -y

# 安装常用工具
echo "正在安装常用工具..."
apt install -y htop curl wget

# 使用 Docker 官方安装脚本安装 Docker
echo "正在使用 Docker 官方安装脚本安装 Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 自动获取并安装最新版本的 Docker Compose
echo "正在安装 Docker Compose..."
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 安装 x-ui
echo "正在安装 x-ui..."
bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)

# 启用 TCP BBR
echo "正在启用 TCP BBR..."
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

echo "安装和配置完成！"
