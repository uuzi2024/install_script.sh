#!/bin/bash

# 显示菜单选项
echo "请选择需要执行的操作:"
echo "1. 更新系统并安装常用安全软件"
echo "2. 安装 Zsh 和插件"
echo "3. 安装 Docker"
echo "4. 安装 WordPress 并开启缓存系统"
echo "5. 关闭甲骨文云防火墙"
echo "6. 全部执行（不包括安装 WordPress）"
echo "7. 退出"

# 获取用户选择
read -p "请输入数字 (1-7): " choice

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
    echo "正在执行全部操作（不包括安装 WordPress）..."
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

  7)
    echo "退出脚本。"
    exit 0
    ;;
  
  *)
    echo "无效选择，请输入 1 到 7 之间的数字。"
    ;;
esac

# 提示框：安装 Zsh 时的手动操作说明
echo "-------------------------------------------------"
echo "注意："
echo "在安装 Zsh 后，你需要编辑配置文件："
echo "执行命令：nano ~/.zshrc"
echo "在文件中添加以下内容："
echo "  plugins=(git zsh-autosuggestions)"
echo "保存后，运行命令：source ~/.zshrc 使更改生效。"
echo "-------------------------------------------------"
