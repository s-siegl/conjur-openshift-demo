#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

#oc_download_url="https://github.com/openshift/origin/releases/download/v3.7.0/openshift-origin-client-tools-v3.7.0-7ed6862-linux-64bit.tar.gz"
oc_download_url="https://github.com/openshift/origin/releases/download/v3.6.1/openshift-origin-client-tools-v3.6.1-008f2d5-linux-64bit.tar.gz" 


echo "${red}Download then extract tar and cp oc tool${reset}"
rm -rf openshift-origin-client-tools-*
wget $oc_download_url 
tar xzvf openshift-origin-client-tools-*.tar.gz
cp -f openshift-origin-client-tools-*/oc /usr/local/bin
echo "${green}Done${reset}"

echo "${red}Startup Openshift cluster${reset}"
oc cluster up
oc cluster down
echo "${green}Done${reset}"

