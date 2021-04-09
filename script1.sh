#!/bin/bash

sshport="$1"
sftpuser="$2"

upgradeSys_installPack() {
	apt update
	apt upgrade -y
	apt install --no-install-recommends -y mysql-server nginx php php-fpm php-mysql unattended-upgrades fail2ban
}

change_ssh_port() {
	defport=`grep '^Port' /etc/ssh/sshd_config`
	if [ -z "$defport" ];
		then printf "Port $sshport" >> /etc/ssh/sshd_config

	fi
	defport=`grep '^Port' /etc/ssh/sshd_config`
	sed -i "s/${defport}/Port ${sshport}/" /etc/ssh/sshd_config
	systemctl restart ssh
}

auto_sec_update() {
	dpkg-reconfigure -f noninteractive unattended-upgrades
}

firewall_setup() {

	ufw default deny incoming
	ufw default allow outgoing
	ufw allow "$sshport"
	ufw allow ssh
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

setup_sftp() {
	if [ -z "$sftpuser" ]; then
		echo "Add name sftpuser par№2"
	else
		useradd   $sftpuser
		echo "Enter password for sftp user"
		passwd $sftpuser
		chown root:root /var
		chmod 755 /var
		chmod 777 -R /var/www
		check=`grep '^Match User $sftpuser' /etc/ssh/sshd_config`
		if [ -z "$check" ];
			then printf "
Match User $sftpuser
	ForceCommand internal-sftp
	PasswordAuthentication yes
	ChrootDirectory /var
	PermitTunnel no
	AllowAgentForwarding no
	AllowTcpForwarding no
	X11Forwarding no" >> /etc/ssh/sshd_config
		fi;
	fi;
	systemctl restart ssh
}

mysql_secure() {

	mysql_secure_installation

}

upgradeSys_installPack
change_ssh_port
firewall_setup
auto_sec_update
setup_default_site
setup_sftp
mysql_secure
