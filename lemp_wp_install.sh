#!/bin/bash

yourdomain="$1"
dbuser="$2"
dbpassword="$3"

packages_install() {
	apt update
	apt install --no-install-recommends -y mariadb-server nginx-light php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip php-cli php-fpm php-mysql php-mysqlnd
}

myisam_conf(){
	printf "[mysqld]
	skip-innodb
	default-storage-engine=MyISAM " > /etc/mysql/conf.d/myisam.cnf
	systemctl restart mysql
}

nginx_default() {
	printf "server {
	listen 80 default_server;
	listen [::]:80 default_server;

	server_tokens off;

	default_type \"text/html\";
	return 200 'Hello, do you want to see the puppies';
	}

server {
	listen 443 ssl default_server;
	listen [::]:443 ssl default_server;

	ssl_certificate default.crt;
	ssl_certificate_key default.key;

	server_tokens off;

	default_type \"text/html\";
	return 200 'Hello, do you want to see the puppies safely';
	}" > /etc/nginx/sites-enabled/default

}

letsencrypt() {
	cd /etc/nginx/
	openssl req -x509 -out default.crt -keyout default.key \
	-newkey rsa:2048 -nodes -sha256 -subj '/CN=localhost' -extensions EXT -config <(printf "
	[dn]
	CN=localhost
	[req]
	distinguished_name = dn
	[EXT]
	subjectAltName=DNS:localhost
	keyUsage=digitalSignature
	extendedKeyUsage=serverAuth")
}
 
setup_default_site() {
	nginx_default
	letsencrypt
	nginx -s reload
}

setup_dehydrated() {
	cd /usr/bin
	wget https://raw.githubusercontent.com/lukas2511/dehydrated/master/dehydrated
	chmod +x dehydrated
	cd~
	mkdir /etc/dehydrated /var/lib/dehydrated /var/lib/dehydrated/acme-challenges  /etc/dehydrated/acme-challenges;
	printf "BASEDIR=/var/lib/dehydrated
		WELLKNOWN=\"\${BASEDIR}/acme-challenges\"
		DOMAINS_TXT=\"/etc/dehydrated/domains.txt\"" > /etc/dehydrated/config
	dehydrated --register --accept-terms
	printf "$yourdomain www.$yourdomain" > /etc/dehydrated/domains.txt

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

dehydrate_update() {

	printf "#!bin/bash

		dehydrated -c -g" > /etc/cron.weekly/Dehydrated
	chmod +x /etc/cron.weekly/Dehydrated
	printf "#!/bin/sh

		test \"\$1\" = \"deploy_cert\" || exit 0
		nginx -s reload" > /etc/dehydrated/hook.sh
	chmod +x /etc/dehydrated/hook.sh
}

wpcli_install() {
	curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
	php wp-cli.phar --info
	chmod +x wp-cli.phar
	sudo mv wp-cli.phar /usr/local/bin/wp
}

wordpress_install(){
	mysql_secure_installation
	mysql -e "CREATE DATABASE wordpress; GRANT ALL ON wordpress.* TO '$dbuser'@'localhost' IDENTIFIED BY '$dbpassword'; FLUSH PRIVILEGES;"
	mkdir /var/www/wordpress
	wp core download --allow-root --path=/var/www/wordpress
	wp core config --path=/var/www/wordpress --allow-root --dbname=wordpress --dbuser=$dbuser --dbpass=$dbpassword --dbhost=localhost --dbprefix=wp_
}

setup_nginx_full() {
	setup_default_site
	setup_dehydrated
	setup_certificate_siteconf
	dehydrate_update
}

setup_wordpress() {
	wpcli_install
	setup_wordpress
}

packages_install
myisam_conf
setup_nginx_full
setup_wordpress