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
#	temp=`echo $defport`
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

#upgradeSys_installPack
change_ssh_port
firewall_setup
