#!/bin/bash

# 显示提示框（提示框颜色为绿色）
echo -e "\e[32m-------------------------------------------------\e[0m"
echo -e "\e[32m注意：\e[0m"
echo -e "\e[32m在安装 Zsh 后，你需要编辑配置文件：\e[0m"
echo -e "\e[32m执行命令：nano ~/.zshrc\e[0m"
echo -e "\e[32m在文件中添加以下内容：\e[0m"
echo -e "\e[32m  plugins=(git zsh-autosuggestions)\e[0m"
echo -e "\e[32m保存后，运行命令：source ~/.zshrc 使更改生效。\e[0m"
echo -e "\e[32m-------------------------------------------------\e[0m"

# 显示菜单选项
echo "请选择需要执行的操作:"
echo "1. 更新系统并安装常用安全软件"
echo "2. 安装 Zsh 和插件"
echo "3. 安装 Docker"
echo "4. 安装 WordPress 并开启缓存系统"
echo "5. 关闭甲骨文云防火墙"
echo "6. 安装代理 (v2ray)"
echo "7. 进行服务器性能测试 (YABS)"
echo "8. 全部执行（不包括安装 WordPress 和 YABS、代理）"
echo "9. 退出"

# 获取用户选择
read -p "请输入数字 (1-9): " choice

# 执行操作
case $choice in
  1)
    echo "正在更新系统并安装常用系统安全软件..."
    bash <(wget -qO- https://bit.ly/tugeupdate)
    ;;
  
  2)
    echo "正在安装 Zsh 和插件..."
    # 安装 Zsh、Git、Curl、Oh My Zsh 和插件
    sudo apt update
    sudo apt install -y zsh git curl
    chsh -s /bin/zsh
    
    # 安装 Oh My Zsh 和插件
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    echo "plugins=(git zsh-autosuggestions)" >> ~/.zshrc
    
    # 使配置生效
    source ~/.zshrc
    ;;
  
  3)
    echo "正在安装 Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    ;;
  
  4)
    echo "正在安装 WordPress 并开启缓存系统..."
    bash <(wget -qO- https://bit.ly/tugewpp)
    ;;
  
  5)
    echo "正在关闭甲骨文云防火墙..."
    # 关闭防火墙
    sudo iptables -P INPUT ACCEPT
    sudo iptables -P FORWARD ACCEPT
    sudo iptables -P OUTPUT ACCEPT
    sudo iptables -F
    sudo apt-get purge -y netfilter-persistent
    ;;
  
  6)
    echo "正在安装 v2ray 代理..."
    bash <(wget -qO- -o- https://git.io/v2ray.sh)
    ;;
  
  7)
    echo "正在进行服务器性能测试 (YABS)..."
    # 安装 curl（如果没有安装的话）
    sudo apt install -y curl
    curl -sL https://yabs.sh | bash
    ;;
  
  8)
    echo "正在执行全部操作（不包括安装 WordPress、YABS 和代理）..."
    bash <(wget -qO- https://bit.ly/tugeupdate)
    
    # 安装 Zsh 和插件
    sudo apt update
    sudo apt install -y zsh git curl
    chsh -s /bin/zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    echo "plugins=(git zsh-autosuggestions)" >> ~/.zshrc
    source ~/.zshrc
    
    # 安装 Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    ;;

  9)
    echo "退出脚本。"
    exit 0
    ;;
  
  *)
    echo "无效选择，请输入 1 到 9 之间的数字。"
    ;;
esac
