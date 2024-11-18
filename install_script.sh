#!/bin/bash

# 检查是否以 root 用户执行
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 用户执行此脚本"
  exit
fi

echo "开始执行脚本..."

# 更新和升级系统
echo "更新和升级系统..."
apt update && apt upgrade -y && apt autoremove -y
echo "系统更新完成"

# 设置系统时区为中国上海
echo "设置系统时区为中国上海..."
timedatectl set-timezone Asia/Shanghai
timedatectl
echo "时区设置完成"

# 安装并配置 UFW 防火墙
echo "安装 UFW 防火墙..."
apt install ufw -y
ufw allow ssh
ufw allow http
ufw allow https
echo "已添加以下规则："
ufw show added
ufw enable
ufw status verbose
echo "UFW 防火墙配置完成"

# 安装 Fail2ban
echo "安装 Fail2ban..."
apt install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban
echo "Fail2ban 安装完成并已启动"

# 启用 BBR
echo "启用 BBR..."
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
  echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
fi
if ! grep -q "net.ipv4.tcp_congestion_control=bbr" /etc/sysctl.conf; then
  echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
fi
sysctl -p
echo "BBR 已启用"

# 安装 V2Ray
echo "安装 V2Ray..."
bash <(wget -qO- -o- https://git.io/v2ray.sh)
echo "V2Ray 安装完成"

echo "脚本执行完成！"
