#!/bin/bash

sshport="$1"

upgradeSys_installPack () {
	apt update
	apt upgrade -y
	apt install --no-install-recommends -y mysql-server nginx php php-fpm php-mysql unattended-upgrades fail2ban
}

change_ssh_port () {
	defport=`grep -c '^Port' /etc/sss/sshd_config`
	sed -i 's/'$defport'/Port '$sshport'/' /etc/ssh/sshd_config
	systemctl restart ssh
}

upgradeSys_installPack
change_ssh_port
