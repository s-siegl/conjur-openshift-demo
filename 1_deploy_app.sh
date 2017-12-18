#!/bin/bash

red=`tput setaf 1`
orange=`tput setaf 166`
green=`tput setaf 2`
blue=`tput setaf 4`
reset=`tput sgr0`
openshift_user="developer"
openshift_pass="password"
timeout="120"

main() {

	echo "${blue}Deploy and init postgres database image${reset}"
	oc login -u $openshift_user -p $openshift_pass
	oc project conjur
	oc create -f deployments/postgres-secrets.yml
	oc create -f deployments/postgres-deployment.yml
	oc volume dc/postgresql --add --name=postgresql-data --type=persistentVolumeClaim --claim-name=postgresql --claim-size=1 --overwrite
	oc create -f deployments/postgres-service.yml 
	output=$(oc describe dc/postgresql)
	output=$(echo $output | sed -E -e 's/[[:blank:]]+//g')
	[[ "$output" =~ "Status:Complete" ]] || { echo "${orange}Warn: Waiting Postgres image to be ready... ${reset}"; }
	progress="#"
	count=0
	while [[ !("$output" =~ "Status:Complete") ]]
	do
		echo -ne "$progress\r"
		sleep 2
		progress="$progress#"
		((count+=1))
		[[ "$count" == "$timeout" ]] && { echo "${red}Timeout $timeout while waiting Postgres image to be ready"; echo "$output ${reset}"; exit 1; }
		output=$(oc describe dc/postgresql); output=$(echo $output | sed -E -e 's/[[:blank:]]+//g');
	done
	echo "${green}Done${reset}"

	echo "${blue}Deploy and init application image${reset}"
	oc new-app wildfly:latest~https://github.com/jamboubou/insultapp-B.git --name='insults' -e POSTGRESQL_USER=insult  -e PGPASSWORD=insult -e POSTGRESQL_DATABASE=insults
	echo "${orange}Warn: Waiting Insults App image to be ready... ${reset}"	
	oc logs -f bc/insults
	output=$(oc describe dc/insults)
	output=$(echo $output | sed -E -e 's/[[:blank:]]+//g')
	[[ "$output" =~ "Status:Complete" ]] || { echo "${red}Error while waiting Insults App image to be ready"; echo "$output ${reset}"; exit 1; }
	echo "${green}Done${reset}"

	echo "${blue}Conigure application and database${reset}"
	oc expose service insults
	oc set probe dc/insults --readiness --get-url=http://:8080/ --initial-delay-seconds=20
	oc describe dc/insults
	echo "${orange}Warn: Waiting Application launch to be finalized for 30s ...${reset}"
	echo -ne '#                         (1%)\r'
	sleep 10
	echo -ne '#####                     (33%)\r'
	sleep 10
	echo -ne '#############             (66%)\r'
	sleep 10
	echo -ne '#######################   (100%)\r'
	echo -ne '\n'
	insults_app_pod_name=$(oc get pods -l app=insults | awk '{print $1}' | tail -1)
	oc rsh $insults_app_pod_name sh init-db.sh
	oc logout
	echo "${green}Done${reset}"

}

clean() {

	echo "${red}Clean Insults App environment${reset}"
	oc login -u $openshift_user -p $openshift_pass
	oc project conjur
	oc delete all -l app=insults
	oc delete -f deployments/postgres-deployment.yml -f deployments/postgres-secrets.yml -f deployments/postgres-service.yml
	oc logout
	echo "${green}Done${reset}"

}

initdb() {

	echo "${red}init Application Database${reset}"
	oc login -u $openshift_user -p $openshift_pass
	oc project conjur
	insults_app_pod_name=$(oc get pods -l app=insults | awk '{print $1}' | tail -1)
	oc rsh $insults_app_pod_name sh init-db.sh
	oc logout
	echo "${green}Done${reset}"

}


case "$1" in
        clean)
            clean
            ;;

        initdb)
            initdb
            ;;
         
        *)
            main
esac


