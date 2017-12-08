#!/bin/bash

red=`tput setaf 1`
orange=`tput setaf 166`
green=`tput setaf 2`
blue=`tput setaf 4`
reset=`tput sgr0`
openshift_user="developer"
openshift_pass="password"
conjur_appliance_version="4.9.6.0"

up() {

echo "${blue}Start docker service${reset}"
systemctl restart docker
systemctl stop firewalld
echo "${green}Done${reset}"


echo "${blue}Start Openshift Cluster${reset}"
oc cluster down
output="$(oc cluster up 2>&1)"
[[ "$output" =~ "Error" ]] && { echo "${red}Failed to setup Openshift cluster, exit with Error:"; echo "$output ${reset}"; exit 1; }
echo "$output"
echo "${green}Done${reset}"


echo "${blue}Configure Openshift to allow root containers to run${reset}"
oc login -u system:admin
oc adm policy add-scc-to-group anyuid system:authenticated
echo "${green}Done${reset}"

echo "${blue}Create demo project and load conjur appliance image${reset}"
oc login -u $openshift_user -p $openshift_pass
oc new-project conjur
docker load -i conjur-appliance/conjur-appliance-${conjur_appliance_version}.tar
docker tag registry.tld/conjur-appliance:${conjur_appliance_version} 172.30.1.1:5000/conjur/conjur-appliance
output="$(docker login -u developer -p $(oc whoami -t) 172.30.1.1:5000 2>&1)"
echo $output
[[ "$output" =~ "Error" ]] && { echo "${orange}Warn: Openshift image may not yet be ready, give it another try after 10s ...${reset}";sleep 10; echo $output; output=$(docker login -u developer -p $(oc whoami -t) 172.30.1.1:5000 2>&1); }
[[ "$output" =~ "Error" ]] && { echo "${orange}Warn: Openshift image may not yet be ready, give it another try after 15 more s ...${reset}";sleep 10; echo $output; output=$(docker login -u developer -p $(oc whoami -t) 172.30.1.1:5000 2>&1); }
[[ "$output" =~ "Error" ]] && { echo "${orange}Warn: Openshift image may not yet be ready, give it another try after 20 more s ...${reset}";sleep 10; echo $output; output=$(docker login -u developer -p $(oc whoami -t) 172.30.1.1:5000 2>&1); }
[[ "$output" =~ "Error" ]] && { echo "${red}Last try, exit with Error: $output ${reset}"; exit 1; }
echo $output
docker push 172.30.1.1:5000/conjur/conjur-appliance
echo "${green}Done${reset}"


echo "${blue}Deploy and init Conjur image in Openshift${reset}"
oc create -f deployments/conjur-deployment.yml
oc create -f deployments/conjur-service.yml
oc create -f deployments/conjur-route.yml
output=$(oc describe dc/conjur-appliance)
output=$(echo $output | sed -E -e 's/[[:blank:]]+//g')
[[ "$output" =~ "Status:Complete" ]] || { echo "${orange}Warn: Conjur image may not yet be ready, give it another try after 3s ...${reset}";sleep 3; output=$(oc describe dc/conjur-appliance); output=$(echo $output | sed -E -e 's/[[:blank:]]+//g'); }
[[ "$output" =~ "Status:Complete" ]] || { echo "${orange}Warn: Conjur image may not yet be ready, give it another try after 5 more s ...${reset}";sleep 5; output=$(oc describe dc/conjur-appliance); output=$(echo $output | sed -E -e 's/[[:blank:]]+//g'); }
[[ "$output" =~ "Status:Complete" ]] || { echo "${orange}Warn: Conjur image may not yet be ready, give it another try after 10 more s ...${reset}";sleep 10; output=$(oc describe dc/conjur-appliance); output=$(echo $output | sed -E -e 's/[[:blank:]]+//g'); }
[[ "$output" =~ "Status:Complete" ]] || { echo "${red}Last try, exit with Error: $output ${reset}"; exit 1; }
conjur_pod_name=$(oc get pods | grep "conjur*" | awk '{print $1}')
oc rsh $conjur_pod_name evoke configure master -h conjur-appliance -p password orgaccount
echo "${green}Done${reset}"

echo "${blue}Finaliazing configuration${reset}"
oc logout
oc login -u system:admin
oc adm policy remove-scc-from-group anyuid system:authenticated
output=$(cat /etc/hosts)
[[ "$output" =~ "conjur-appliance" ]] || echo "172.30.94.192 conjur-appliance" >> /etc/hosts
echo "${green}You can now connect to Openshift on https://localhost:8443 login: developer password: password${reset}"
echo "${green}You can now connect to Conjur appliance on https://conjur-appliance login: admin password: password${reset}"
echo "${green}END${reset}"


}

down() {

echo "${red}Shutting down the demo env${reset}"
oc cluster down
echo "${green}Done${reset}"

}



case "$1" in
        up)
            up
            ;;
         
        down)
            down
            ;;
         
        *)
            echo $"Usage: $0 {up|down}"
            exit 1
esac