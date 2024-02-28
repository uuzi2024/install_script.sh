顺序调整：


#!/bin/bash

# Define colors for highlighting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ip_address() {
ipv4_address=$(curl -s ipv4.ip.sb)
ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
}

# Function to check if Docker is installed
check_docker_installed() {
    if command -v docker &>/dev/null; then
        echo -e "${YELLOW}提示:${NC} Docker 已经安装在系统中."
        return 0
    else
        return 1
    fi
}

# Function to check if Docker Compose is installed
check_docker_compose_installed() {
    if command -v docker-compose &>/dev/null; then
        echo -e "${YELLOW}提示:${NC} Docker Compose 已经安装在系统中."
        return 0
    else
        return 1
    fi
}

# Function to display system information
show_system_info() {
    clear
    ip_address
    if [ "$(uname -m)" == "x86_64" ]; then
      cpu_info=$(cat /proc/cpuinfo | grep 'model name' | uniq | sed -e 's/model name[[:space:]]*: //')
    else
      cpu_info=$(lscpu | grep 'BIOS Model name' | awk -F': ' '{print $2}' | sed 's/^[ \t]*//')
    fi

    if [ -f /etc/alpine-release ]; then
        # Alpine Linux 使用以下命令获取 CPU 使用率
        cpu_usage_percent=$(top -bn1 | grep '^CPU' | awk '{print " "$4}' | cut -c 1-2)
    else
        # 其他系统使用以下命令获取 CPU 使用率
        cpu_usage_percent=$(top -bn1 | grep "Cpu(s)" | awk '{print " "$2}')
    fi


    cpu_cores=$(nproc)

    mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')

    disk_info=$(df -h | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')

    country=$(curl -s ipinfo.io/country)
    city=$(curl -s ipinfo.io/city)

    isp_info=$(curl -s ipinfo.io/org)

    cpu_arch=$(uname -m)

    hostname=$(hostname)

    kernel_version=$(uname -r)

    congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
    queue_algorithm=$(sysctl -n net.core.default_qdisc)

    # 尝试使用 lsb_release 获取系统信息
    os_info=$(lsb_release -ds 2>/dev/null)

    # 如果 lsb_release 命令失败，则尝试其他方法
    if [ -z "$os_info" ]; then
      # 检查常见的发行文件
      if [ -f "/etc/os-release" ]; then
        os_info=$(source /etc/os-release && echo "$PRETTY_NAME")
      elif [ -f "/etc/debian_version" ]; then
        os_info="Debian $(cat /etc/debian_version)"
      elif [ -f "/etc/redhat-release" ]; then
        os_info=$(cat /etc/redhat-release)
      else
        os_info="Unknown"
      fi
    fi

    output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
        NR > 2 { rx_total += $2; tx_total += $10 }
        END {
            rx_units = "Bytes";
            tx_units = "Bytes";
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "KB"; }
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "MB"; }
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "GB"; }

            if (tx_total > 1024) { tx_total /= 1024; tx_units = "KB"; }
            if (tx_total > 1024) { tx_total /= 1024; tx_units = "MB"; }
            if (tx_total > 1024) { tx_total /= 1024; tx_units = "GB"; }

            printf("总接收: %.2f %s\n总发送: %.2f %s\n", rx_total, rx_units, tx_total, tx_units);
        }' /proc/net/dev)


    current_time=$(date "+%Y-%m-%d %I:%M %p")


    swap_used=$(free -m | awk 'NR==3{print $3}')
    swap_total=$(free -m | awk 'NR==3{print $2}')

    if [ "$swap_total" -eq 0 ]; then
        swap_percentage=0
    else
        swap_percentage=$((swap_used * 100 / swap_total))
    fi

    swap_info="${swap_used}MB/${swap_total}MB (${swap_percentage}%)"

    runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}')

    echo ""
    echo -e "${GREEN}================= 系统信息 ================= ${NC}"
    echo ""
    echo -e "${GREEN}硬件信息：${NC}"
    echo "CPU架构: $cpu_arch"
    echo "CPU型号: $cpu_info"
    echo "CPU核心数: $cpu_cores"
    echo "CPU占用: $cpu_usage_percent%"
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo -e "${GREEN}系统信息：${NC}"
    echo "系统版本: $os_info"
    echo "Linux版本: $kernel_version"
    echo "物理内存: $mem_info"
    echo "虚拟内存: $swap_info"
    echo "硬盘占用: $disk_info"
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo -e "${GREEN}主机信息：${NC}"
    echo "主机名: $hostname"
    echo "运营商: $isp_info"
    echo "公网IPv4地址: $ipv4_address"
    echo "公网IPv6地址: $ipv6_address"
    echo "网络拥堵算法: $congestion_algorithm $queue_algorithm"
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo "$output"
    echo "地理位置: $country $city"
    echo "系统时间: $current_time"
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo "系统运行时长: $runtime"
    echo ""
    read -p "按任意键返回主菜单..." -n 1 -r
    show_menu
}

# Function to update the system and enable BBR
update_system_and_enable_bbr() {
    clear
    echo -e "${GREEN}============= 更新系统开启BBR加速 ============== ${NC}"
    echo "执行更新系统的命令..."
    sudo apt update && sudo apt upgrade -y
    echo -e "${GREEN}系统更新完成。${NC}"

    # 检查是否已经启用了BBR
    if [[ $(lsmod | grep -w tcp_bbr) ]]; then
    echo -e "${GREEN}BBR 已经启用，无需重复开启。${NC}"
    else
        echo "执行开启BBR的命令..."
        # 开启BBR
        sudo modprobe tcp_bbr
        echo "tcp_bbr" | sudo tee -a /etc/modules-load.d/modules.conf
        echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
        echo "BBR 已成功启用！"
    fi

    echo ""
    read -p "按任意键返回主菜单..." -n 1 -r
    show_menu
}


# Function to install Docker and Docker Compose
install_docker() {
    clear
    echo -e "${GREEN}========= 安装Docker和Docker Compose =========${NC}"
    
    if check_docker_installed && check_docker_compose_installed; then
        echo ""
        read -p "按任意键返回主菜单..." -n 1 -r
        show_menu
    fi
    
    if ! check_docker_installed; then
        echo "执行安装Docker的命令..."
        sudo apt update
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker $USER
        sudo systemctl enable docker
        sudo systemctl start docker
        echo "Docker已安装！"
    fi
    
    if ! check_docker_compose_installed; then
        echo "执行安装Docker Compose的命令..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo "Docker Compose已安装！"
    fi
    
    echo ""
    read -p "按任意键返回主菜单..." -n 1 -r
    show_menu
}

# Function to uninstall Docker and Docker Compose
uninstall_docker() {
    clear
    echo -e "${GREEN}=========== 卸载Docker和Docker Compose ===========${NC}"
    
    if ! check_docker_installed && ! check_docker_compose_installed; then
        echo -e "${YELLOW}提示:${NC} 系统中未安装 Docker 和 Docker Compose."
        echo ""
        read -p "按任意键返回主菜单..." -n 1 -r
        show_menu
    fi
    
    echo -e "${YELLOW}提示:${NC} 这条命令会删除所有与 Docker 相关的数据，包括镜像、容器、卷等，运行之前，请确保您已经备份了所有重要的数据，小心操作"
    echo ""
    read -p "是否继续？(按 Enter 继续, 按 0 取消): " confirm
    if [[ "$confirm" == "0" ]]; then
        echo "取消卸载操作"
        show_menu
    fi
    
    if check_docker_installed; then
        echo "执行卸载 Docker 的命令..."
        sudo apt-get purge  -y docker-ce docker-ce-cli containerd.io
        sudo rm -rf /var/lib/docker
        sudo rm -rf /etc/docker
        sudo groupdel docker
        echo "Docker 已卸载！"
    fi
    
    if check_docker_compose_installed; then
        echo "执行卸载 Docker Compose 的命令..."
        sudo rm -rf /usr/local/bin/docker-compose
        echo "Docker Compose 已卸载！"
    fi
    
    echo ""
    show_menu
}

# Function to change system time
change_system_time() {
    clear
    echo -e "${GREEN}================= 系统时间 ================= ${NC}"
    echo -e "${YELLOW}1.${NC} 中国上海"
    echo -e "${YELLOW}2.${NC} 美国纽约"
    echo -e "${YELLOW}3.${NC} 英国伦敦"
    echo -e "${YELLOW}4.${NC} 日本东京"
    echo -e "${YELLOW}5.${NC} 澳大利亚悉尼"
    echo -e "${YELLOW}6.${NC} 加拿大温哥华"
    echo -e "${YELLOW}7.${NC} 德国柏林"
    echo -e "${YELLOW}0.${NC} 返回主菜单"
    echo -e "${YELLOW}请选择要修改时间的地区: ${NC}"
    read choice
    case $choice in
        1) sudo timedatectl set-timezone Asia/Shanghai ;;
        2) sudo timedatectl set-timezone America/New_York ;;
        3) sudo timedatectl set-timezone Europe/London ;;
        4) sudo timedatectl set-timezone Asia/Tokyo ;;
        5) sudo timedatectl set-timezone Australia/Sydney ;;
        6) sudo timedatectl set-timezone America/Vancouver ;;
        7) sudo timedatectl set-timezone Europe/Berlin ;;
        0) show_menu ;;
        *) echo "无效选项，请重新选择" && change_system_time ;;
    esac
    echo "系统时间已修改！"
    echo ""
    read -p "按任意键返回主菜单..." -n 1 -r
    show_menu
}

# Function to clean up the file system
clean_filesystem() {
    clear
    echo -e "${GREEN}=============== 文件系统清理 =============== ${NC}"
    echo -e "${YELLOW}1.${NC} 删除临时文件"
    echo -e "${YELLOW}2.${NC} 清理日志文件"
    echo -e "${YELLOW}3.${NC} 清理系统缓存"
    echo -e "${YELLOW}4.${NC} 一键清理所有临时、日志和缓存文件"
    echo -e "${YELLOW}0.${NC} 返回主菜单"
    echo -e "${YELLOW}请选择要执行的操作: ${NC}"
    read choice
    case $choice in
        1) sudo rm -rf /tmp/* ;;
        2) sudo rm -rf /var/log/*.log ;;
        3) sudo apt clean ;;
        4) clean_all_files ;;
        0) show_menu ;;
        *) echo "无效选项，请重新选择" && clean_filesystem ;;
    esac
    echo "文件系统清理完成！"
    echo ""
    read -p "按任意键返回主菜单..." -n 1 -r
    show_menu
}

clean_all_files() {
    sudo rm -rf /tmp/* /var/log/*.log /var/cache/apt/archives/*.deb
}
# Function to display current port usage
show_port_usage() {
    clear
    echo -e "${GREEN}=============== 端口占用情况 =============== ${NC}"
    echo ""
    echo -e "${GREEN}当前系统端口占用情况:${NC}"
    sudo netstat -tuln
    echo ""
    read -p "按任意键返回主菜单..." -n 1 -r
    show_menu
}

# Function to add Docker project for traffmonetizer
add_docker_project_traffmonetizer() {
    clear
    echo -e "${GREEN}docker项目traffmonetizer${NC}"
    read -p "请输入 token: " token
    docker_command="docker run -d --restart=always --name tm traffmonetizer/cli_v2 start accept --token $token"
    echo "执行部署代码: $docker_command"
    # 执行部署代码
    $docker_command
    echo -e "${GREEN}traffmonetizer 项目已成功添加！${NC}"
    read -p "按任意键返回主菜单..." -n 1 -r
    show_menu
}

# Function to list running Docker projects with creation time and current status
list_running_docker_projects() {
    clear
    echo -e "${GREEN}当前运行的 Docker 项目：${NC}"
    docker ps --format "项目名称: {{.Names}}\n生成时间: {{.CreatedAt}}\n运行状态: {{.Status}}\n"
    read -p "按任意键返回主菜单..." -n 1 -r
    show_menu
}

# Function to display main menu
show_menu() {
    clear
    echo -e "${GREEN}================= 兔哥脚本 ================= ${NC}"
    echo -e "脚本版本： ${YELLOW}V1.0.0${NC}       更新时间： ${YELLOW}2024-2-28${NC}"
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo -e ""
    echo -e "${YELLOW}1.${NC} 查看系统信息"
    echo -e "${YELLOW}2.${NC} 更新系统和开启BBR"
    echo -e "${YELLOW}3.${NC} 安装Docker和Docker Compose"
    echo -e "${YELLOW}4.${NC} 卸载Docker和Docker Compose"
    echo -e "${YELLOW}5.${NC} 修改系统时间"
    echo -e "${YELLOW}6.${NC} 文件系统清理"
    echo -e "${YELLOW}7.${NC} 查看端口占用情况"
    echo -e "${YELLOW}8.${NC} 部署docker项目traffmonetizer"
    echo -e "${YELLOW}9.${NC} 查看系统中运行的docker项目"
    echo -e ""
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo -e ""
    echo -e "${YELLOW}0.${NC} ${GREEN}退出${NC}"
    echo -e ""
    echo -e "${YELLOW}请选择操作: ${NC}"
    read choice
    case $choice in
        1) show_system_info ;;
        2) update_system_and_enable_bbr ;;
        3) install_docker ;;
        4) uninstall_docker ;;
        5) change_system_time ;;
        6) clean_filesystem ;;
        7) show_port_usage ;;
        8) add_docker_project_traffmonetizer ;;
        9) list_running_docker_projects ;;
        0) exit ;;
        *) echo "无效选项，请重新选择" && show_menu ;;
    esac
}
# Start the script by displaying the main menu
show_menu
