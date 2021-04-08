#!/bin/bash

yourdomain="$1"
 
install_certboot() {
	apt update
	apt install -y python3-certbot-nginx

} 
 
nginx_configure() {
	mkdir /var/www/"$yourdomain"  /var/www/"$yourdomain"/html

	printf "
server {
        listen 80;
        listen [::]:80;
        root /var/www/$yourdomain/html;
        index index.html index.htm index.nginx-debian.html;
        server_name $yourdomain www.$yourdomain;
        location / {
                try_files \$uri \$uri/ =404;
        }
}" > /etc/nginx/sites-enabled/"$yourdomain"

	nginx -s reload
}

setup_ssl() {
certbot --nginx -d "$yourdomain" -d www."$yourdomain"
}

install_certboot
nginx_configure
setup_ssl