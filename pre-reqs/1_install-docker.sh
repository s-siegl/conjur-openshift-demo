#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echo "${red}Remove old docker and setup repo${reset}"
yum remove docker docker-common docker-selinux docker-engine
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum makecache fast
yum install docker-ce-17.09.1.ce-1.el7.centos
echo "${green}Done${reset}"

echo "${red}Config docker network${reset}"
systemctl restart docker
docker network inspect -f "{{range .IPAM.Config }}{{ .Subnet }}{{end}}" bridge
sed -i '/^ExecStart=.*/c\ExecStart=/usr/bin/dockerd --insecure-registry 172.30.0.0/16' /usr/lib/systemd/system/docker.service
systemctl restart docker
echo "${green}Done${reset}"

