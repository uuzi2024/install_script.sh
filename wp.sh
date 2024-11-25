#!/bin/bash
green() {
    echo -e "\033[32m\033[01m$1\033[0m"
}
# 更新软件包列表并升级已安装的软件包
apt update && apt upgrade -y
apt autoremove -y

# 允许SSH、HTTP和HTTPS流量通过防火墙
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

# 添加并更新Nginx的PPA源
sudo add-apt-repository ppa:ondrej/nginx -y
sudo apt update -y

# 安装Nginx并进行配置
sudo apt dist-upgrade -y
sudo apt install nginx -y

# 检查Nginx配置并重启Nginx服务
sudo nginx -t
sudo service nginx restart

# 添加并更新PHP的PPA源
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update -y

# 安装PHP及其相关模块
sudo apt install php8.3-fpm php8.3-common php8.3-mysql \
php8.3-xml php8.3-xmlrpc php8.3-curl php8.3-gd \
php8.3-imagick php8.3-cli php8.3-dev php8.3-imap \
php8.3-mbstring php8.3-opcache php8.3-redis \
php8.3-soap php8.3-zip -y

sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/8.3/fpm/php.ini 
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/' /etc/php/8.3/fpm/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 64M/' /etc/php/8.3/fpm/php.ini
systemctl restart php8.3-fpm

sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default

# 设置要写入的配置内容
CONFIG_CONTENT="
user www-data;
worker_processes 1;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    multi_accept on;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 15;
    types_hash_max_size 2048;
    server_tokens off;
    client_max_body_size 64m;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ssl_protocols TLSv1.2 TLSv1.3; # 更安全的 TLS 版本
    ssl_prefer_server_ciphers on;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    gzip_proxied any;
    gzip_comp_level 5;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    fastcgi_cache_key "\$scheme\$request_method\$host\$request_uri";
    add_header Fastcgi-Cache \$upstream_cache_status;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;

    server {
        listen 80 default_server;
        listen [::]:80 default_server;
        server_name _;
        return 444;
    }
}
"

# 将配置写入nginx源配置文件
echo "$CONFIG_CONTENT" | sudo tee /etc/nginx/nginx.conf > /dev/null

# 重新加载nginx配置
sudo nginx -t && sudo systemctl reload nginx

curl -sSL https://mariadb.org/mariadb_release_signing_key.asc | gpg --dearmor > /usr/share/keyrings/mariadb.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mariadb.gpg] https://mirror-cdn.xtom.com/mariadb/repo/10.11/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/mariadb.list
sudo apt update && sudo apt install mariadb-server  -y
systemctl enable mariadb
systemctl stop nginx

read -p "请输入网站名称（英文）:" domain
curl https://get.acme.sh | sh
    ln -s  /root/.acme.sh/acme.sh /usr/local/bin/acme.sh
    acme.sh --set-default-ca --server letsencrypt
    green "已输入的域名：$domain"
    mkdir -p /var/www/$domain/logs /var/www/$domain/public /var/www/$domain/ssl /var/www/$domain/cache /var/www/$domain/backups
    realip=$(curl -s ipv4.ip.sb)
    domainIP=$(dig +short "$domain")
	if [ -z "$domain" ]; then
    		echo "请先设置域名变量" && exit 1
	fi
   if [ "$realip" = "$domainIP" ]; then
        echo '域名解析OK' && sleep 3;
        bash ~/.acme.sh/acme.sh --issue -d ${domain} --standalone -k ec-256;
        bash ~/.acme.sh/acme.sh --install-cert -d ${domain} --key-file /var/www/$domain/ssl/$domain.key --fullchain-file /var/www/$domain/ssl/$domain.crt --ecc;
        green "证书申请成功！脚本申请到的证书（cert.crt）和私钥（private.key）已保存到 /var/www/$domain/ssl 文件夹";
    else
        echo '请检查域名是否已解析到该VPS' && sleep 3;
    fi

chmod -R 755 /var/www/$domain
chown www-data:www-data -R /var/www/$domain/public/
cat >> /etc/nginx/sites-available/$domain << EOF
fastcgi_cache_path /var/www/$domain/cache levels=1:2 keys_zone=$domain:100m inactive=60m;
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name $domain;

    ssl_certificate /var/www/$domain/ssl/$domain.crt;
    ssl_certificate_key /var/www/$domain/ssl/$domain.key;

    access_log /var/www/$domain/logs/access.log;
    error_log /var/www/$domain/logs/error.log;

    root /var/www/$domain/public/;
    index index.php;

    set \$skip_cache 0;

    # POST requests and urls with a query string should always go to PHP
    if (\$request_method = POST) {
        set \$skip_cache 1;
    }   
    if (\$query_string != "") {
        set \$skip_cache 1;
    }   

    # Don’t cache uris containing the following segments
    if (\$request_uri ~* "/wp-admin/|/xmlrpc.php|wp-.*.php|/feed/|index.php|sitemap(_index)?.xml") {
        set \$skip_cache 1;
    }   

    # Don’t use the cache for logged in users or recent commenters
    if (\$http_cookie ~* "comment_author|wordpress_[a-f0-9]+|wp-postpass|wordpress_no_cache|wordpress_logged_in") {
        set \$skip_cache 1;
    }


    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_cache_bypass \$skip_cache;
        fastcgi_no_cache \$skip_cache;
        fastcgi_cache $domain;
        fastcgi_cache_valid 60m;
    }
}

server {
    listen 80;
    listen [::]:80;

    server_name $domain;

    return 301 https://$domain\$request_uri;
}
EOF



systemctl start nginx
sudo ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/$domain
systemctl reload nginx

cd /var/www/$domain/public
wget https://cn.wordpress.org/latest-zh_CN.zip
apt install unzip -y
unzip latest-zh_CN.zip
mv wordpress/* .
rm latest-zh_CN.zip

rm -rf /var/www/$domain/cache/*
