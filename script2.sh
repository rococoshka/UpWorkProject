#!/bin/bash
yourdomain="$1"

setup_dehydrated() {
	
	mkdir /etc/dehydrated /var/lib/dehydrated /var/lib/dehydrated/acme-challenges  /etc/dehydrated/acme-challenges;
	printf "BASEDIR=/var/lib/dehydrated
		WELLKNOWN=\"\${BASEDIR}/acme-challenges\"
		DOMAINS_TXT=\"/etc/dehydrated/domains.txt\"" > /etc/dehydrated/config
	dehydrated --register --accept-terms
	printf "$yourdomain www.$yourdomain\n" >> /etc/dehydrated/domains.txt
}

setup_certificate_siteconf() {
	printf "server {
		listen 80;
		server_name $yourdomain www.$yourdomain;
		location ^~ /.well-known/acme-challenge {
			alias /var/lib/dehydrated/acme-challenges;
			}
		location / {
			return 301 https://\$host\$request_uri; }
	}" > /etc/nginx/sites-enabled/$yourdomain.conf

	nginx -s reload
dehydrated -c
}

setup_ssl_nginx() {
	printf "server {
      listen 443 ssl;
      server_name $yourdomain www.$yourdomain;

      ssl_certificate     /var/lib/dehydrated/certs/xx.ru/fullchain.pem;
      ssl_certificate_key /var/lib/dehydrated/certs/xx.ru/privkey.pem;
	  
	  root /var/www/html;
      index index.php index.html index.htm index.nginx-debian.html;
	  
	  location / {
                try_files \$uri \$uri/ =404;
        }

        location ~ \\.php\$ {
                include snippets/fastcgi-php.conf;
                fastcgi_pass unix:/var/run/php/php7.2-fpm.sock;
        }

        location ~ //\.ht {
                deny all;
        }
}
	}" >> /etc/nginx/sites-enabled/$yourdomain.conf

	nginx -s reload
}


dehydrate_update() {

	printf "#!bin/bash

		dehydrated -c -g" > /etc/cron.weekly/Dehydrated
	chmod +x /etc/cron.weekly/Dehydrated
	printf "#!/bin/sh

		test \"\$1\" = \"deploy_cert\" || exit 0
		nginx -s reload" > /etc/dehydrated/hook.sh
	chmod +x /etc/dehydrated/hook.sh
}

setup_dehydrated
setup_certificate_siteconf
setup_ssl_nginx
dehydrate_update
