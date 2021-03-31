#!/bin/bash

sshport="$1"

upgradeSys_installPack () {
	apt update
	apt upgrade -y
	apt install --no-install-recommends -y mysql-server nginx php php-fpm php-mysql unattended-upgrades fail2ban
}

change_ssh_port () {
	sed -i 's/Port 22/Port "$sshport"/' /etc/ssh/sshd_config
	systemctl restart ssh
}

change_ssh_port
