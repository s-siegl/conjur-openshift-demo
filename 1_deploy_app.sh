#!/bin/bash

red=`tput setaf 1`
orange=`tput setaf 166`
green=`tput setaf 2`
blue=`tput setaf 4`
reset=`tput sgr0`
openshift_user="developer"
openshift_pass="password"


echo "${blue}Deploy and init postgres database image${reset}"
oc login -u $openshift_user -p $openshift_pass
oc project conjur
oc create -f deployments/postgres-secrets.yml
oc create -f deployments/postgres-deployment.yml
oc volume dc/postgresql --add --name=postgresql-data --type=persistentVolumeClaim --claim-name=postgresql --claim-size=1
oc create -f deployments/postgres-service.yml
output=$(oc describe dc/postgresql)
output=$(echo $output | sed -E -e 's/[[:blank:]]+//g')
[[ "$output" =~ "Status:Complete" ]] || { echo "${orange}Warn: Postgres image may not yet be ready, give it another try after 5s ...${reset}";sleep 5; output=$(oc describe dc/postgresql); output=$(echo $output | sed -E -e 's/[[:blank:]]+//g'); }
[[ "$output" =~ "Status:Complete" ]] || { echo "${orange}Warn: Postgres image may not yet be ready, give it another try after 8 more s ...${reset}";sleep 8; output=$(oc describe dc/postgresql); output=$(echo $output | sed -E -e 's/[[:blank:]]+//g'); }
[[ "$output" =~ "Status:Complete" ]] || { echo "${orange}Warn: Postgres image may not yet be ready, give it another try after 10 more s ...${reset}";sleep 10; output=$(oc describe dc/postgresql); output=$(echo $output | sed -E -e 's/[[:blank:]]+//g'); }
[[ "$output" =~ "Status:Complete" ]] || { echo "${red}Last try, exit with Error: $output ${reset}"; exit 1; }
echo "${green}Done${reset}"

echo "${blue}Deploy and init application image${reset}"
oc new-app wildfly:latest~https://github.com/jamboubou/insultapp-B.git --name='insults' -e POSTGRESQL_USER=insult  -e PGPASSWORD=insult -e POSTGRESQL_DATABASE=insults
#oc env dc insults -e POSTGRESQL_USER=insult  -e PGPASSWORD=insult -e POSTGRESQL_DATABASE=insults
output=$(oc describe dc/insults)
output=$(echo $output | sed -E -e 's/[[:blank:]]+//g')
[[ "$output" =~ "Status:Complete" ]] || { echo "${orange}Warn: Application image may not yet be ready, give it another try after 30s ...${reset}";sleep 30; output=$(oc describe dc/insults); output=$(echo $output | sed -E -e 's/[[:blank:]]+//g'); }
[[ "$output" =~ "Status:Complete" ]] || { echo "${orange}Warn: Application image may not yet be ready, give it another try after 60 more s ...${reset}";sleep 60; output=$(oc describe dc/insults); output=$(echo $output | sed -E -e 's/[[:blank:]]+//g'); }
[[ "$output" =~ "Status:Complete" ]] || { echo "${orange}Warn: Application image may not yet be ready, give it another try after 120 more s ...${reset}";sleep 120; output=$(oc describe dc/insults); output=$(echo $output | sed -E -e 's/[[:blank:]]+//g'); }
[[ "$output" =~ "Status:Complete" ]] || { echo "${red}Last try, exit with Error: $output ${reset}"; exit 1; }
echo "${green}Done${reset}"

echo "${blue}Conigure application and database${reset}"
oc expose service insults
oc set probe dc/insults --readiness --get-url=http://:8080/
echo "${orange}Warn: Waiting Application launch to be finalized for 30s ...${reset}";sleep 30;
insults_app_pod_name=$(oc get pods | grep "insults*" | awk '{print $1}' | tail -1)
oc rsh $insults_app_pod_name sh init-db.sh
oc logout
echo "${green}Done${reset}"



