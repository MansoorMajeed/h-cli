#!/bin/bash

# The installer for Ubuntu that will install 
# Nginx + PHP-FPM + MySQL


###############################################
# Warning : Only for ubuntu
###############################################

if [ -f '/etc/os-release' ];then
        source /etc/os-release
        if [ $ID != "ubuntu" ];then
                echo "Does not look like an Ubuntu system"
                echo "Exiting"
                exit

        fi
else
        echo "Does not look like an Ubuntu system"
        echo "Exiting"
        exit
fi



echo "This script will install Nginx + PHP-FPM + MySQL"
echo "Are you sure you want to continue? "

echo "Updating apt cache.."
apt-get update -y
echo "Installing Nginx..."
apt-get install nginx
service nginx start

echo "Installing MySQL"
apt-get install mysql-server -y
sleep 1
echo "========================================================="
echo "= Setting up MySQL server. Follow onscreen instructions ="
echo "========================================================="
mysql_install_db
mysql_secure_installation
sleep 1
echo "Installing PHP-FPM"
apt-get install php5-fpm php5-mysql php5-gd php5-cli -y

check=`grep -E "^cgi.fix_pathinfo=0" conf`
if [ -z $check ];then
        echo "cgi.fix_pathinfo=0" >> conf
fi

service php5-fpm restart

cp -f /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak

cat > /etc/nginx/sites-available/default <<EOL

# Add the full nginx conf here
server {
    listen 80 default_server;
    listen [::]:80 default_server ipv6only=on;

    root /usr/share/nginx/html;
    index index.php index.html index.htm;

    server_name server_domain_name_or_IP;

    location / {
        try_files $uri $uri/ =404;
    }

    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}

EOL
service nginx restart

echo "all done. Make sure your installtion works"
echo "<?php phpinfo(); ?>" > /usr/share/nginx/html/info.php
echo "Open a browser and load [http://your-ip/info.php] "

