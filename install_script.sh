#!/bin/bash

# 定义颜色和进度条函数
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
BOLD='\033[1m'
UNDERLINE='\033[4m'

progress_bar() {
    pid=$1
    t=0
    max=20 # 进度条的最大长度
    p="█"
    while kill -0 $pid 2>/dev/null; do
        if [ $t -lt $max ]; then
            t=$((t+1))
            printf "\r[${GREEN}${p:0:$t}${NC}%.0s] $t%%"
        else
            printf "\r[${GREEN}${p:0:$max}${NC}%.0s] $t%%"
        fi
        sleep 1
    done
    printf "\r[${GREEN}${p:0:$max}${NC}%.0s] 100%%\n"
}

error_exit() {
    echo -e "${RED}错误: $1${NC}"
    exit 1
}

echo -e "${GREEN}一键自动安装脚本 1.0${NC}"
echo -e "${GREEN}更新时间 2024-1-12${NC}"

# 分割线
echo -e "${GREEN}=================================================${NC}"

# 确保脚本以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    error_exit "请以 root 权限运行此脚本"
fi

# 显示系统信息
echo -e "${GREEN}显示系统信息:${NC}"
echo "操作系统：$(lsb_release -d | cut -f2)"
echo "内核版本：$(uname -r)"
echo "CPU 信息：$(lscpu | grep 'Model name' | cut -d ':' -f2 | xargs)"
echo "总计内存：$(free -h | grep 'Mem' | awk '{print $2}')"
sleep 3

# 更新软件包和系统
echo -e "${GREEN}正在更新软件包和系统...${NC}"
DEBIAN_FRONTEND=noninteractive apt-get update > /dev/null &
apt_get_pid=$!
progress_bar $apt_get_pid
wait $apt_get_pid
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o Dpkg::Options::="--force-confold" > /dev/null &
apt_get_pid=$!
progress_bar $apt_get_pid
wait $apt_get_pid && update_status="成功" || update_status="失败"

# 安装常用工具
echo -e "${GREEN}正在安装常用工具...${NC}"
apt-get install -y htop curl wget > /dev/null &
apt_get_pid=$!
progress_bar $apt_get_pid
wait $apt_get_pid && tools_status="成功" || tools_status="失败"

# 使用 Docker 官方安装脚本安装 Docker
echo -e "${GREEN}正在使用 Docker 官方安装脚本安装 Docker...${NC}"
curl -fsSL https://get.docker.com -o get-docker.sh
bash get-docker.sh > /dev/null 2>&1 &
apt_get_pid=$!
progress_bar $apt_get_pid
wait $apt_get_pid && docker_status="成功" || docker_status="失败"

# 自动获取并安装最新版本的 Docker Compose
echo -e "${GREEN}正在安装 Docker Compose...${NC}"
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose > /dev/null 2>&1
chmod +x /usr/local/bin/docker-compose > /dev/null 2>&1 &
apt_get_pid=$!
progress_bar $apt_get_pid
wait $apt_get_pid && compose_status="成功" || compose_status="失败"

# 启用 TCP BBR
echo -e "${GREEN}正在启用 TCP BBR...${NC}"
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p > /dev/null &
apt_get_pid=$!
progress_bar $apt_get_pid
wait $apt_get_pid && bbr_status="成功" || bbr_status="失败"

# 显示结束报告
echo -e "${GREEN}${BOLD}${UNDERLINE}安装和配置报告:${NC}${BOLD}"
echo "1. 系统更新：${update_status}"
echo "2. 常用工具安装：${tools_status}"
echo "3. Docker 安装：${docker_status}"
echo "4. Docker Compose 安装：${compose_status}"
echo "5. TCP BBR 启用：${bbr_status}"
echo -e "${NC}"
echo -e "${GREEN}所有操作完成！${NC}"
