#!/bin/bash

sshport="$1"

upgradeSys_installPack () {
	apt update
	apt upgrade -y
	apt install --no-install-recommends -y mysql-server nginx php php-fpm php-mysql unattended-upgrades fail2ban
}

change_ssh_port () {
	defport=`grep '^Port' /etc/ssh/sshd_config`
	if [ -z "$defport" ];
		then defport=`grep '^#Port' /etc/ssh/sshd_config`

	fi
	sed -i "s/${defport}/Port ${sshport}/" /etc/ssh/sshd_config
	systemctl restart ssh
}

firewall_setup () {

	ufw default deny incoming
	ufw default allow outgoing
	ufw allow "$sshport"
	ufw allow http
	ufw allow https
	ufw enable

}

nginx_default() {
	printf "server {
	listen 80 default_server;
	listen [::]:80 default_server;
	server_tokens off;
	default_type \"text/html\";
	return 200 'This is default http';
	}
server {
	listen 443 ssl default_server;
	listen [::]:443 ssl default_server;
	ssl_certificate default.crt;
	ssl_certificate_key default.key;
	server_tokens off;
	default_type \"text/html\";
	return 200 'This is default https';
	}" > /etc/nginx/sites-enabled/default

}

certkeygen() {
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
	certkeygen
	nginx -s reload
}

#upgradeSys_installPack
change_ssh_port
firewall_setup
setup_default_site
