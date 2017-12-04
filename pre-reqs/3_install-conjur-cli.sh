#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echo "${red}Install Pre-Requisites${reset}"
yum install gcc-c++ patch readline readline-devel zlib zlib-devel
yum install libyaml-devel libffi-devel openssl-devel make
yum install bzip2 autoconf automake libtool bison iconv-devel sqlite-devel
echo "${green}Done${reset}"

echo "${red}Install rvm to deploy ruby${reset}"
curl -sSL https://rvm.io/mpapis.asc | gpg --import -
curl -L get.rvm.io | bash -s stable
source /etc/profile.d/rvm.sh
rvm reload
echo "${green}Done${reset}"

echo "${red}Verify dependecies${reset}"
rvm requirements run
echo "${green}Done${reset}"

echo "${red}Install Ruby 2.2.4${reset}"
rvm install 2.2.4
echo "${green}Done${reset}"

echo "${red}Setup default Ruby version${reset}"
rvm use 2.2.4 --default
ruby --version
echo "${green}Done${reset}"

echo "${red}Install gem command line utility and Conjur CLI gem${reset}"
yum install gem
gem install conjur-cli -v 5.2.5
conjur plugin install policy
echo "${green}Done${reset}"
