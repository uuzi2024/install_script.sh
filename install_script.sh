#!/bin/bash
# Define colors for highlighting
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ln -sf ~/sh.sh /usr/local/bin/t
wget -O do-cli-namager.sh https://raw.githubusercontent.com/uuzi2024/install_script.sh/main/do-cli-namager.sh && chmod +x do-cli-namager.sh
wget -O vultr-cli-manager.sh https://raw.githubusercontent.com/uuzi2024/install_script.sh/main/vultr-cli-manager.sh && chmod +x vultr-cli-manager.sh
#查询ipv4和ipv6地址
ip_address() {
ipv4_address=$(curl -s ipv4.ip.sb)
ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
}
# 检查是否安装docker
check_docker_installed() {
    if command -v docker &>/dev/null; then
        echo -e "${YELLOW}提示:${NC} Docker 已经安装在系统中."
        return 0
    else
        return 1
    fi
}
# 显示系统信息
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
    #congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
    #queue_algorithm=$(sysctl -n net.core.default_qdisc)
    congestion_algorithm=$(cat /proc/sys/net/ipv4/tcp_congestion_control)
    queue_algorithm=$(cat /proc/sys/net/core/default_qdisc)
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
    echo "地理位置: $country $city"
    echo "系统时间: $current_time"
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo "系统运行时长: $runtime"
    echo ""
    read -p "按任意键返回上级菜单..." -n 1 -r
    show_system_menu
}
# 更新系统开启BBR加速
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
    read -p "按任意键返回上级菜单..." -n 1 -r
    show_menu
}
# 安装Docker和Docker Compose
install_docker() {
    echo -e "${GREEN}========= 安装Docker和Docker Compose =========${NC}"
    
    if command -v docker &>/dev/null; then
        echo "Docker 已经安装在系统中，无需重复安装"
        read -p "按任意键返回上级菜单..." -n 1 -r
        show_docker_menu
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
        echo "执行安装Docker Compose的命令..."
        sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        echo -e "${YELLOW}Docker和Docker Compose已安装！${NC}"
    fi
    
    echo ""
    read -p "按任意键返回上级菜单..." -n 1 -r
    show_docker_menu
}
# 卸载docker和docker compose
uninstall_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "\e[1;31m系统中未安装 Docker 和 Docker Compose. 无需卸载\e[0m"
        echo ""
        read -p "按任意键返回上级菜单..." -n 1 -r
        show_docker_menu
    fi
    
    echo -e "${YELLOW}提示:${NC} 这条命令会删除所有与 Docker 相关的数据，包括镜像、容器、卷等，运行之前，请确保您已经备份了所有重要的数据，小心操作"
    echo ""
    read -p "是否继续？(按 Enter 继续, 按 0 取消): " confirm
    if [[ "$confirm" == "0" ]]; then
        echo -e "${YELLOW}取消卸载操作${NC}"
        echo ""
        read -p "按任意键返回上级菜单..." -n 1 -r
        show_docker_menu
    fi
    
    if command -v docker &>/dev/null; then
        echo -e "${YELLOW}正在执行卸载docker和docker compose......${NC}"
        sudo apt-get purge  -y docker-ce docker-ce-cli containerd.io
        sudo rm -rf /var/lib/docker
        sudo rm -rf /etc/docker
        sudo groupdel docker
        echo "执行卸载 Docker Compose 的命令..."
        sudo rm -rf /usr/local/bin/docker-compose
        echo -e "${YELLOW}docker和docker compose已成功卸载${NC}"
    fi
    
    echo ""
    read -p "按任意键返回上级菜单..." -n 1 -r
    show_docker_menu
}
# 更改系统时间
change_system_time() {
    current_timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
    current_time=$(date)
    #current_time_formatted=$(date +"%A %B %d %T %Y" -d "${current_time}")
    current_time=$(date -d "${current_time}" +"%Y年%m月%d日 %H:%M:%S")

    clear
    echo -e "${GREEN}================= 系统时间 ================= ${NC}"
    echo -e "${YELLOW}当前系统时间 (${current_timezone}): ${NC}${current_time}"
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
        1) timezone="Asia/Shanghai"; region="中国上海" ;;
        2) timezone="America/New_York"; region="美国纽约" ;;
        3) timezone="Europe/London"; region="英国伦敦" ;;
        4) timezone="Asia/Tokyo"; region="日本东京" ;;
        5) timezone="Australia/Sydney"; region="澳大利亚悉尼" ;;
        6) timezone="America/Vancouver"; region="加拿大温哥华" ;;
        7) timezone="Europe/Berlin"; region="德国柏林" ;;
        0) show_menu ;;
        *) echo "无效选项，请重新选择" && change_system_time ;;
    esac
    
    sudo timedatectl set-timezone $timezone
    modified_time=$(date)
    #modified_time_formatted=$(date +"%A %B %d %T %Y" -d "${current_time}")
    modified_time=$(date -d "${modified_time}" +"%Y年%m月%d日 %H:%M:%S")
    
    #echo "已将系统时间修改为${region}时间 (${timezone})"
    #echo "当前时间为：${modified_time}"
    echo -e "\e[1;33m已将系统时间修改为\e[0m\e[1;36m${region}时间 (${timezone})\e[0m"
    echo -e "\e[1;33m当前时间为：\e[0m\e[1;36m${modified_time}\e[0m"

    echo ""
    read -p "按任意键返回上级菜单..." -n 1 -r
    show_system_menu
}
# 清理系统文件
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
    read -p "按任意键返回上级菜单..." -n 1 -r
    show_system_menu
}
clean_all_files() {
    sudo rm -rf /tmp/* /var/log/*.log /var/cache/apt/archives/*.deb
}
# 系统端口占用情况
show_port_usage() {
    clear
    echo -e "${GREEN}=============== 端口占用情况 =============== ${NC}"
    echo ""
    echo -e "${GREEN}当前系统端口占用情况:${NC}"
    sudo netstat -tuln
    echo ""
    read -p "按任意键返回上级菜单..." -n 1 -r
    show_system_menu
}
# 使用docker部署traffmonetizer
add_docker_project_traffmonetizer() {
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "\e[1;31m无法部署项目，请先返回主菜单安装 Docker 和 Docker Compose。\e[0m"
        read -p "按任意键返回上级菜单..." -n 1 -r
        show_docker_menu
    fi

    # Check if traffmonetizer container is already running
    if docker ps -a --format '{{.Names}}' | grep -q "^tm$"; then
        echo -e "\e[1;31mtraffmonetizer 已经在 Docker 中运行，无需重复部署。\e[0m"
        read -p "按任意键返回上级菜单..." -n 1 -r
        show_docker_menu
    fi

    echo -e "${GREEN}正在部署docker项目traffmonetizer${NC}"

    while true; do
        #read -p "请输入 token 或输入 0 返回主菜单:" token
        read -p $'\e[1;33m请输入 token 或输入 0 返回上级菜单:\e[0m ' token

        if [[ $token == 0 ]]; then
            show_docker_menu
            break
        fi

        # 判断 token 是否为 44 个字符
        if [[ ${#token} -ne 44 ]]; then
            #echo "请输入正确的 44 个字符的 token："
            echo -e "\e[1;31mtoken格式错误，请重新输入\e[0m"
            continue
        fi

        docker_command="docker run -d --restart=always --name tm traffmonetizer/cli_v2 start accept --token $token"
        #echo "执行部署代码: $docker_command"
        echo -e "\e[1;32m执行部署代码: $docker_command\e[0m"

        # 执行部署代码
        $docker_command
        echo -e "${GREEN}traffmonetizer 项目已成功添加！${NC}"
        read -p "按任意键返回上级菜单..." -n 1 -r
        show_docker_menu
    done
}
# 列出当前系统运行的docker项目
list_running_docker_projects() {   
    # 判断系统是否安装了 Docker
    if ! command -v docker &>/dev/null; then
        ##echo "系统未安装 Docker，无任何项目可显示。"
        echo -e "\e[1;31m当前系统未安装Docker，无任何项目可显示\e[0m"
    else
        echo -e "${GREEN}当前运行的 Docker 项目：${NC}"
        docker ps --format "项目名称: {{.Names}}\n生成时间: {{.CreatedAt}}\n运行状态: {{.Status}}\n"
    fi
    
    read -p "按任意键返回上级菜单..." -n 1 -r
    show_docker_menu
}
# 使用docker部署wordpress
add_docker_project_wordpress() {
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "\e[1;31m无法部署项目，请先返回主菜单安装 Docker 和 Docker Compose。\e[0m"
        read -p "按任意键返回上级菜单..." -n 1 -r
        show_docker_menu
    fi

    # Check if WordPress container is already running
if docker ps -a --format '{{.Names}}' | grep -qE 'wordpress'; then
        echo -e "\e[1;31mWordPress 已经在 Docker 中运行，无需重复部署。\e[0m"
        read -p "按任意键返回上级菜单..." -n 1 -r
        show_docker_menu
    fi

    echo -e "${GREEN}正在部署 WordPress 项目...${NC}"

    # 创建所需目录并赋予 777 权限
    mkdir -p /var/docker_data/wordpress /var/docker_data/mariadb
    chmod 777 /var/docker_data/wordpress /var/docker_data/mariadb
    
    # 创建所需目录和文件
    mkdir -p /var/docker_item/wordpress
    touch /var/docker_item/wordpress/docker-compose-wordpress.yml
    
    # 询问博客名称
    read -p "请输入博客名称: " WORDPRESS_BLOG_NAME
    # 询问用户名
    read -p "请输入用户名: " WORDPRESS_USERNAME
    # 询问密码，不隐藏输入字符
    echo -e -n "${YELLOW}请输入密码: ${NC}"
    read WORDPRESS_PASSWORD
    echo
    # 提示正在部署
    echo -e "${GREEN}请牢记以上信息，正在部署请稍后......${NC}"
    echo
    
    # 定义 Docker Compose 配置文件的路径
    COMPOSE_FILE="/var/docker_item/wordpress/docker-compose-wordpress.yml"

    # 创建 Docker Compose 配置文件
    cat > $COMPOSE_FILE <<EOL
version: '2'
services:
  mariadb:
    image: docker.io/bitnami/mariadb:11.2
    volumes:
      - /var/docker_data/mariadb:/bitnami/mariadb
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
      - MARIADB_USER=bn_wordpress
      - MARIADB_DATABASE=bitnami_wordpress
    restart: always

  wordpress:
    image: docker.io/bitnami/wordpress:6
    ports:
      - '80:8080'
      - '443:8443'
    volumes:
      - /var/docker_data/wordpress:/bitnami/wordpress
    depends_on:
      - mariadb
    environment:
      - ALLOW_EMPTY_PASSWORD=yes
      - WORDPRESS_DATABASE_HOST=mariadb
      - WORDPRESS_DATABASE_PORT_NUMBER=3306
      - WORDPRESS_DATABASE_USER=bn_wordpress
      - WORDPRESS_DATABASE_NAME=bitnami_wordpress
      - WORDPRESS_USERNAME=${WORDPRESS_USERNAME}
      - WORDPRESS_PASSWORD=${WORDPRESS_PASSWORD}
      - WORDPRESS_BLOG_NAME=${WORDPRESS_BLOG_NAME}
EOL

    # 使用 Docker Compose 启动容器
    docker-compose -f $COMPOSE_FILE up -d

    # 提示用户 WordPress 项目已经部署完成
    echo -e "${GREEN}WordPress 项目已经部署完成。${NC}"
    echo -e "${GREEN}博客地址：http:$(curl -s ipv4.ip.sb)${NC}"
    echo -e "${GREEN}博客后台地址：http:$(curl -s ipv4.ip.sb)/wp-admin${NC}"
    read -p "按任意键返回上级菜单..." -n 1 -r
    show_docker_menu
}
# 使用docker部署uptime kuma
add_docker_project_uptime_kuma() {
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "\e[1;31m无法部署项目，请先返回主菜单安装 Docker 和 Docker Compose。\e[0m"
        read -p "按任意键返回上级菜单..." -n 1 -r
        show_docker_menu
    fi

    # Check if Uptime Kuma container is already running
    if docker ps -a --format '{{.Names}}' | grep -qE 'uptime-kuma'; then
        echo -e "\e[1;31mUptime Kuma 已经在 Docker 中运行，无需重复部署。\e[0m"
        read -p "按任意键返回上级菜单..." -n 1 -r
        show_docker_menu
    fi

    echo -e "${GREEN}正在部署 Uptime Kuma 项目...${NC}"

    # 创建所需目录
    mkdir -p /var/docker_data/uptime_kuma
    chmod 777 /var/docker_data/uptime_kuma
    mkdir -p /var/docker_item/uptime_kuma
    touch /var/docker_item/uptime_kuma/docker-compose.yml
    # 定义 Docker Compose 配置文件的路径
    COMPOSE_FILE_uptime_kuma="/var/docker_item/uptime_kuma/docker-compose.yml"

    # 创建 Docker Compose 配置文件
    cat > $COMPOSE_FILE_uptime_kuma <<EOL
version: '3'
services:
  uptime-kuma:
    image: louislam/uptime-kuma:1
    volumes:
      - /var/docker_data/uptime_kuma:/app/data
    ports:
      # <Host Port>:<Container Port>
      - '3001:3001'
    restart: unless-stopped
EOL

    # 使用 Docker Compose 启动容器
    docker-compose -f $COMPOSE_FILE_uptime_kuma up -d

    # 提示用户 Uptime Kuma 项目已经部署完成
    echo -e "${GREEN}Uptime Kuma 项目已经部署完成。${NC}"
    echo -e "${GREEN}Uptime Kuma 可在 http:$(curl -s ipv4.ip.sb):3001 访问。${NC}"
    read -p "按任意键返回上级菜单..." -n 1 -r
    show_docker_menu
}
add_docker_project_umami() {
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "\e[1;31m无法部署项目，请先返回主菜单安装 Docker 和 Docker Compose。\e[0m"
        read -p "按任意键返回上级菜单..." -n 1 -r
        show_docker_menu
    fi

    # Check if Umami container is already running
    if docker ps -a --format '{{.Names}}' | grep -qE 'umami'; then
        echo -e "\e[1;31mUmami 已经在 Docker 中运行，无需重复部署。\e[0m"
        read -p "按任意键返回上级菜单..." -n 1 -r
        show_docker_menu
    fi

    echo -e "${GREEN}正在部署 Umami 项目...${NC}"

    # 创建所需目录
    mkdir -p /var/docker_data/umami
    chmod 777 /var/docker_data/umami
    mkdir -p /var/docker_item/umami
    touch /var/docker_item/umami/docker-compose.yml

    # 定义 Docker Compose 配置文件的路径
    COMPOSE_FILE_umami="/var/docker_item/umami/docker-compose.yml"

    # 创建 Docker Compose 配置文件
    cat > $COMPOSE_FILE_umami <<EOL
---
version: '3'
services:
  umami:
    image: ghcr.io/umami-software/umami:postgresql-latest
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://umami:umami@db:5432/umami
      DATABASE_TYPE: postgresql
      APP_SECRET: replace-me-with-a-random-string
    depends_on:
      db:
        condition: service_healthy
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "curl http://localhost:3000/api/heartbeat"]
      interval: 5s
      timeout: 5s
      retries: 5
    volumes:
      - umami-db-data:/var/lib/postgresql/data
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: umami
      POSTGRES_USER: umami
      POSTGRES_PASSWORD: umami
    volumes:
      - umami-db-data:/var/lib/postgresql/data
    restart: always
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $${POSTGRES_USER} -d $${POSTGRES_DB}"]
      interval: 5s
      timeout: 5s
      retries: 5
volumes:
  umami-db-data:
    driver: local
    driver_opts:
      type: none
      device: /var/docker_data/umami
      o: bind
EOL

    # 使用 Docker Compose 启动容器
    docker-compose -f $COMPOSE_FILE_umami up -d

    # 提示用户 Umami 项目已经部署完成
    echo -e "${GREEN}Umami 项目已经部署完成。${NC}"
    echo -e "${GREEN}默认用户名为 admin，密码为 umami${NC}"
    echo -e "${GREEN}Umami 可在 http:$(curl -s ipv4.ip.sb):3000 访问。${NC}"
    read -p "按任意键返回上级菜单..." -n 1 -r
    show_docker_menu
}

# 清空docker
restore_default_docker_state() {
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        echo -e "\e[1;31m无法清空，请先返回主菜单安装 Docker 和 Docker Compose。\e[0m"
        read -p "按任意键返回上级菜单..." -n 1 -r
        show_docker_menu
    fi

    echo -e "${YELLOW}正在清空所有 Docker 项目并重置 Docker 守护进程...${NC}"
    rm -rf /var/docker_data/wordpress /var/docker_data/mariadb
    # 停止并删除所有运行中的容器
    docker rm -f $(docker ps -aq) >/dev/null 2>&1
    # 删除所有网络
    docker network prune -f >/dev/null 2>&1
    # 删除所有镜像
    docker rmi -f $(docker images -aq) >/dev/null 2>&1
    # 删除所有卷
    docker volume prune -f >/dev/null 2>&1
    # 重置 Docker 守护进程
    sudo systemctl restart docker
    echo -e "${GREEN}所有 Docker 项目已清空并且 Docker 守护进程已重置，恢复为初始状态。${NC}"
    read -p "按 Enter 返回 Docker 管理菜单" enter_key
    show_docker_menu
}
# 子菜单：系统管理
show_system_menu() {
    clear
    echo -e "${GREEN}================= 系统管理 ================= ${NC}"
    echo -e "脚本版本： ${YELLOW}V1.0.0${NC}       更新时间： ${YELLOW}2024-2-28${NC}"
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo -e ""
    echo -e "${YELLOW}1.${NC} 显示系统信息"
    echo -e "${YELLOW}2.${NC} 更改系统时间"  
    echo -e "${YELLOW}3.${NC} 清理文件系统"      
    echo -e "${YELLOW}4.${NC} 显示端口使用情况"    
    echo -e ""
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo -e ""
    echo -e "${YELLOW}0.${NC} ${GREEN}返回上级菜单${NC}                  ${YELLOW}00.${NC} ${GREEN}退出脚本${NC}"
    ##echo -e "${YELLOW}00.${NC} ${GREEN}退出脚本${NC}"
    echo -e ""
    echo -e "${YELLOW}请选择操作: ${NC}"
    read choice
    case $choice in
        1) show_system_info ;;
        2) change_system_time ;;
        3) clean_filesystem ;;
        4) show_port_usage ;;        
        0) show_menu ;;
        00) exit ;;
        *) echo "无效选项，请重新选择" && show_system_menu ;;
    esac
}
# 子菜单：docker管理   
show_docker_menu() {
    clear
    echo -e "${GREEN}================ Docker管理 ================ ${NC}"
    echo -e "脚本版本： ${YELLOW}V1.0.0${NC}       更新时间： ${YELLOW}2024-2-28${NC}"
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo -e ""

    # 检查Docker是否安装，获取版本和已安装的项目列表
    #docker_installed=$(command -v docker)
    # docker_version=$(docker --version 2>&1)
    # if [[ $docker_version == *"command not found"* ]]; then
    # #if [ -z "$docker_installed" ]; then
    #     echo -e "${RED}当前未安装 Docker.${NC}"
    # else
    #     docker_version=$(docker --version | awk '{print $3}')
    #     echo -e "当前系统已安装Docker 版本为：${YELLOW}${docker_version}${NC}"
    # fi

    echo -e ""
    echo -e "${YELLOW}1.${NC} 安装Docker和Docker Compose"
    echo -e "${YELLOW}2.${NC} 卸载Docker和Docker Compose"
    echo -e "${YELLOW}3.${NC} 部署Docker项目: TraffMonetizer"
    echo -e "${YELLOW}4.${NC} 显示运行中的Docker项目"
    echo -e "${YELLOW}5.${NC} 部署WordPress"
    echo -e "${YELLOW}6.${NC} 清空所有Docker项目恢复至新装docker状态"
    echo -e "${YELLOW}7.${NC} 部署uptime-kuma"
    echo -e "${YELLOW}8.${NC} 部署网站统计工具umami"
    echo -e ""
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo -e ""
    echo -e "${YELLOW}0.${NC} ${GREEN}返回主菜单${NC}                  ${YELLOW}00.${NC} ${GREEN}退出脚本${NC}"
    ##echo -e "${YELLOW}00.${NC} ${GREEN}退出脚本${NC}"
    echo -e ""
    echo -e "${YELLOW}请选择操作: ${NC}"
    read choice
    case $choice in
        1) install_docker ;;
        2) uninstall_docker ;;
        3) add_docker_project_traffmonetizer ;;
        4) list_running_docker_projects ;;
        5) add_docker_project_wordpress ;;    
        6) restore_default_docker_state ;;
        7) add_docker_project_uptime_kuma ;;
        8) add_docker_project_umami ;;
        0) show_menu ;;
        00) exit ;;
        *) echo "无效选项，请重新选择" && show_docker_menu ;;
    esac
}

show_menu() {
    clear
    echo -e "${GREEN}================= 兔哥脚本 ================= ${NC}"
    echo -e "脚本版本： ${YELLOW}V1.0.0${NC}       更新时间： ${YELLOW}2024-2-28${NC}"
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo -e ""
    echo -e "${YELLOW}1.${NC} 更新系统开启BBR"
    echo -e "${YELLOW}2.${NC} 系统信息查看及管理"
    echo -e "${YELLOW}3.${NC} Docker项目管理"
    echo -e "${YELLOW}4.${NC} vultr cli 管理"
    echo -e "${YELLOW}5.${NC} do cli 管理"       
    echo -e ""
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo -e ""
    echo -e "${YELLOW}0.${NC} ${GREEN}退出脚本${NC}"
    echo -e ""
    echo -e "${YELLOW}请选择操作: ${NC}"
    read choice
    case $choice in
        1) update_system_and_enable_bbr ;;
        2) show_system_menu && show_menu ;;
        3) show_docker_menu && show_menu ;;
        4) bash vultr-cli-manager.sh ;;
        5) bash do-cli-namager.sh ;;
        0) exit ;;
        *) echo "无效选项，请重新选择" && show_menu ;;
    esac
}
# 开始执行脚本，显示主菜单
show_menu