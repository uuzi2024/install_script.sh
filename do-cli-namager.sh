install_wget_and_curl() {
    # Check if wget is installed
    if ! command -v wget &>/dev/null; then
        echo -e "安装 wget..."
        sudo apt-get update
        sudo apt-get install wget -y || { echo -e "安装 wget 失败。"; exit 1; }
    fi
    
    # Check if curl is installed
    if ! command -v curl &>/dev/null; then
        echo -e "安装 curl..."
        sudo apt-get update
        sudo apt-get install curl -y || { echo -e "安装 curl 失败。"; exit 1; }
    fi
}
check_architecture_and_execute() {
    local architecture=$(uname -m)
    
    case "$architecture" in
        arm* | aarch*)
            echo "ARM 架构"
            # 执行代码1
            # 在这里执行 ARM 架构的代码
                # 检查是否已安装 Vultr CLI
            clear
            if command -v doctl &> /dev/null; then
                #echo "do CLI 已安装，无需重复安装"
                echo -e "\e[1;33mdo CLI 已安装，无需重复安装\e[0m"
                echo ""
                return
            fi
            install_wget_and_curl    
            # 指定要安装的 Vultr CLI 版本
            local doctl_VERSION="1.104.0"
            local DOWNLOAD_URL="https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-arm64.tar.gz"
            
            # 下载 Vultr CLI
            wget $DOWNLOAD_URL
            # 解压文件
            tar -zxvf docli-${doctl_VERSION}-linux-arm64.tar.gz
            # 移动二进制文件到 PATH 可访问的位置
            sudo mv doctl /usr/local/bin/
            # 设置执行权限
            sudo chmod +x /usr/local/bin/doctl
            # 清理下载的压缩文件
            rm doctl-${doctl_VERSION}-linux-amd64.tar.gz
            
            # 验证安装成功
            echo -e "\e[1;33mdo CLI 安装成功!\e[0m"
            read -n 1 -s -r -p "按任意键返回主菜单"
            clear
            show_menu
            ;;
        x86_64)
            echo "AMD 架构"
            # 执行代码2
            # 在这里执行 AMD 架构的代码
            clear
            if command -v doctl &> /dev/null; then
                echo -e "\e[1;33mdo CLI 已安装，无需重复安装\e[0m"
                echo ""
                return
            fi
            install_wget_and_curl    
            # 指定要安装的 Vultr CLI 版本
            local doctl_VERSION="1.104.0"
            local DOWNLOAD_URL="https://github.com/digitalocean/doctl/releases/download/v1.104.0/doctl-1.104.0-linux-amd64.tar.gz"
            
            # 下载 Vultr CLI
            wget $DOWNLOAD_URL
            # 解压文件
            tar -zxvf doctl-${doctl_VERSION}-linux-amd64.tar.gz
            # 移动二进制文件到 PATH 可访问的位置
            sudo mv doctl /usr/local/bin/
            # 设置执行权限
            sudo chmod +x /usr/local/bin/doctl
            # 清理下载的压缩文件
            rm doctl-${doctl_VERSION}-linux-amd64.tar.gz
            
            # 验证安装成功
            echo -e "\e[1;33mdo CLI 安装成功!\e[0m"
            read -n 1 -s -r -p "按任意键返回主菜单"
            clear
            show_menu
            ;;
        *)
            echo "未知架构: $architecture"
            exit 1
            ;;
    esac
}
# 调用函数
input_do_token(){
    doctl auth init
    clear
    echo -e "\e[1;33mdo账号信息:\e[0m"
    # echo "账号邮箱："doctl account get --format Email | grep -oE '[[:alnum:].]+@[[:alnum:].]+'
    # echo "实例限额："doctl account get --format DropletLimit | awk 'NR==2 {print $1}'
    # echo "账号状态："doctl doctl account get --format Status | awk 'NR==2 {print $1}'
    echo "账号邮箱：$(doctl account get --format Email | grep -oE '[[:alnum:].]+@[[:alnum:].]+')"
    echo "实例限额：$(doctl account get --format DropletLimit | awk 'NR==2 {print $1}')"
    echo "账号状态：$(doctl account get --format Status | awk 'NR==2 {print $1}')"
    # read -n 1 -s -r -p "按任意键到管理菜单"
    # echo -e ""
    # echo -e ""
    instance_manager
}
list_instances() {
    printf "%-18s %-8s %-5s %-7s %-s\n" "公网IPv4" "内存" "CPU" "硬盘" "  区域"
    doctl compute droplet list --format "PublicIPv4,Memory,VCPUs,Disk,Region" --no-header | awk '{$2=$2/1024"G"; printf "%-17s %-7s %-4s %-6s %-s\n", $1, $2, $3, $4, $5}'
    echo ""
    instance_manager
}

add_instance(){
    clear
    echo -e "\e[1;35m直接创建最便宜的套餐4美元/月:\e[0m"
    echo "1. 美国纽约一区--debian 12系统"
    echo "2. 美国旧金山三区--debian 12系统"
    echo "3. 荷兰阿姆斯特丹三区--debian 12系统"
    echo "4. 新加坡一区--debian 12系统"
    echo "5. 德国法兰克福一区--debian 12系统"
    echo "6. 澳大利亚悉尼一区--debian 12系统"
    echo -e "\e[1;35m输入对应的数字选择国家和地区:\e[0m"
    read -r region_choice
    clear
    # 根据用户的选择设置相应的地区代码
    result=$(doctl compute ssh-key list)
    ssh_key_id=$(echo "$result" | awk 'NR==2 {print $1}')
    case $region_choice in
        1) doctl compute droplet create --region nyc1 --image debian-12-x64 --size s-1vcpu-512mb-10gb --ssh-keys $ssh_key_id nyc1;;
        2) doctl compute droplet create --region sfo3 --image debian-12-x64 --size s-1vcpu-512mb-10gb --ssh-keys $ssh_key_id sfo3;;
        3) doctl compute droplet create --region ams3 --image debian-12-x64 --size s-1vcpu-512mb-10gb --ssh-keys $ssh_key_id ams3;;
        4) doctl compute droplet create --region sgp1 --image debian-12-x64 --size s-1vcpu-512mb-10gb --ssh-keys $ssh_key_id sgp1;;
        5) doctl compute droplet create --region fra1 --image debian-12-x64 --size s-1vcpu-512mb-10gb --ssh-keys $ssh_key_id fra1;;
        6) doctl compute droplet create --region syd1 --image debian-12-x64 --size s-1vcpu-512mb-10gb --ssh-keys $ssh_key_id syd1;;
        *) echo "无效的选择"; return;;
    esac
}
delete_instance(){
    printf "%-18s %-16s %-8s %-5s %-9s %-s\n" "实例ID" "公网IPv4" "内存" "CPU" "硬盘" "区域"
    doctl compute droplet list --format "ID,PublicIPv4,Memory,VCPUs,Disk,Region" --no-header | awk '{$3=$3/1024"G"; printf "%-14s %-17s %-7s %-4s %-6s %-s\n", $1, $2, $3, $4, $5, $6}'
    echo ""
    read -p $'\e[1;33m请输入你想要删除的实例ID（输入00取消删除操作）: \e[0m' instance_id
    if [ "$instance_id" = "00" ]; then
        echo -e "\e[1;33m取消删除操作\e[0m"
        show_menu

    else
        doctl compute droplet delete "$instance_id" -f > /dev/null 2>&1
        echo -e "\e[1;33m该实例已成功删除\e[0m"
    fi
}
restall_instance(){
    clear
    printf "%-18s %-16s %-8s %-5s %-9s %-s\n" "实例ID" "公网IPv4" "内存" "CPU" "硬盘" "区域"
    doctl compute droplet list --format "ID,PublicIPv4,Memory,VCPUs,Disk,Region" --no-header | awk '{$3=$3/1024"G"; printf "%-14s %-17s %-7s %-4s %-6s %-s\n", $1, $2, $3, $4, $5, $6}'
    echo -n $'\e[1;33m请输入你想要重装系统的实例ID（输入00取消删除操作）:\e[0m' 
    read instance_id
    if [ "$instance_id" = "00" ]; then
        echo -e "\e[1;33m取消删除操作\e[0m"
        show_menu
    else
        doctl compute droplet-action rebuild "$instance_id" --image debian-12-x64 > /dev/null 2>&1
        echo -e "\e[1;33m该实例正在重装系统...请稍后...\e[0m"
    fi
}
bulk_start_instances() {
    clear
    limit=$(doctl account get --format DropletLimit | awk 'NR==2 {print $1}')
    result=$(doctl compute ssh-key list)
    ssh_key_id=$(echo "$result" | awk 'NR==2 {print $1}')
    echo "当前账号实例限额：$limit"
    echo -en $'\e[1;33m请输入开机脚本（输入00取消操作）:\e[0m\n'
    IFS='' read -r -d '++' user_data
    #echo "$user_data"
    printf "%s\n" "$user_data" > user_data_script.sh
    #exit;
    if [ "$user_data" = "00" ]; then
        echo -e "\e[1;33m取消输入操作\e[0m"
        show_menu
    else
    #echo "$user_data" > user_data_script.sh
    echo ""
    echo -en $'\e[1;33m正在部署,请稍后...:\e[0m\n'
    for ((i=1; i<=limit; i++)); do
            # 在这里编写开启实例的逻辑
            #doctl compute droplet create --region nyc1 --image debian-12-x64 --size s-1vcpu-512mb-10gb --ssh-keys $ssh_key_id --user-data '$user_data' nyc1
            doctl compute droplet create --region nyc1 --image debian-12-x64 --size s-1vcpu-512mb-10gb --ssh-keys $ssh_key_id --user-data-file user_data_script.sh nyc1
            # doctl create droplet 或者其他启动实例的命令
    done
    fi
}
delete_all_instances() {
    droplet_ids=$(doctl compute droplet list --format ID --no-header)
    
    for droplet_id in $droplet_ids; do
        echo "正在删除实例 $droplet_id"
        doctl compute droplet delete $droplet_id --force
    done
}

instance_manager(){
    while true; do
    echo -e "${GREEN}============= 兔哥 do 管理脚本 ============= ${NC}"
    echo -e "电报交流： ${YELLOW}https://t.me/uuzichat${NC}"
    echo -e "博客交流： ${YELLOW}https://uuzi.net/${NC}"  
    echo -e "${GREEN}--------------------------------------------${NC}"
        echo -e ""
        echo "1. 查看实例"
        echo "2. 添加实例"
        echo "3. 删除实例"
        echo "4. 实例重装系统"
        echo "5. 批量开机并部署开机脚本"
        echo "6. 一键清空所有实例"
        echo "0. 退出脚本"
        echo -e ""
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo -e ""
        #read -p "请输入你的选择: " choice
        read -p $'\e[1;33m请输入你的选择: \e[0m' choice

        case $choice in
            1)
                list_instances
                ;;
            2)
                add_instance
                ;;
            3)
                delete_instance
                ;;
            4)
                restall_instance
                ;;   
            5)
                bulk_start_instances
                ;;  
            6)
                delete_all_instances
                ;;  
            0)
                exit 0
                ;;
            *)
                clear
                echo -e "\e[1;33m无效选择，请重新输入。\e[0m"
                show_menu
                break
                ;;
        esac
    done
}
show_menu() {
    clear
    while true; do
    echo -e "${GREEN}============= 兔哥 do 管理脚本 ============= ${NC}"
    echo -e "脚本版本： ${YELLOW}V1.0.0${NC}       更新时间： ${YELLOW}2024-3-6${NC}"
    echo -e "电报交流： ${YELLOW}https://t.me/uuzichat${NC}"
    echo -e "博客交流： ${YELLOW}https://uuzi.net/${NC}"    
    echo -e "${GREEN}--------------------------------------------${NC}"
        echo -e ""
        echo "1. 安装do cli工具(使用脚本必须安装此工具)"
        echo "2. 输入do token"
        echo "3. 实例管理"
        echo "0. 退出脚本"
        echo -e ""
    echo -e "${GREEN}--------------------------------------------${NC}"
    echo -e ""
        #read -p "请输入你的选择: " choice
        read -p $'\e[1;33m请输入你的选择: \e[0m' choice

        case $choice in
            1)
                check_architecture_and_execute
                ;;
            2)
                input_do_token
                ;;
            3)
                instance_manager
                ;;
            0)
                exit 0
                ;;
            *)
                clear
                echo -e "\e[1;33m无效选择，请重新输入。\e[0m"
                show_menu
                break
                ;;
        esac
    done
}
# 调用函数
show_menu