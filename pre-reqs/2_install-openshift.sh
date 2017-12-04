#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echo "${red}Download then extract tar and cp oc tool${reset}"
wget https://github.com/openshift/origin/releases/download/v3.6.1/openshift-origin-client-tools-v3.6.1-008f2d5-linux-64bit.tar.gz 
tar xzvf openshift-origin-client-tools-v3.6.1-008f2d5-linux-64bit.tar.gz
cp openshift-origin-client-tools-v3.6.1-008f2d5-linux-64bit/oc /usr/local/bin
echo "${green}Done${reset}"

echo "${red}Startup Openshift cluster${reset}"
oc cluster up
oc cluster down
echo "${green}Done${reset}"

