#!/bin/bash 
#

#####
# HARD CODED VALUES from policies/policy.yml in parent directory
declare HOST_FACTORY_NAME=insultapp/wildfly_factory
declare openshift_user="developer"
declare openshift_pass="password"
declare SECRET_VAR_NAME="insultapp/database/password"
declare USERNAME_VAR_NAME="insultapp/database/username"
declare HF_TIMEOUT="130"
export CONJUR_APPLIANCE_URL="https://conjur-appliance/api"
export CONJUR_CERT_FILE=/root/conjur-orgaccount.pem
######

# data specs and time math are not portable - set DATE_SPEC to the correct platform
readonly MAC_DATE='date -v+"$dur_time_secs"S +%Y-%m-%dT%H%%3A%M%%3A%S%z'
readonly LINUX_DATE='date --iso-8601=seconds --date="$dur_time_secs seconds"'
DATE_SPEC=$MAC_DATE
if [[ "$(uname -s)" == "Linux" ]]; then
        DATE_SPEC=$LINUX_DATE
fi

# global variables
declare ADMIN_SESSION_TOKEN
declare CONJUR_HOST_FACTORY_TOKEN
declare URLIFIED

##################
# USER AUTHN - get admin session token based on user name and password
# - no arguments
user_authn() {
        printf "\nEnter admin user name: "
        read admin_name
        printf "Enter the admin password (it will not be echoed): "
        read -s admin_pwd
        # Login user, authenticate and get API key for session
        local access_token=$(curl \
                                 -s \
                                --cacert $CONJUR_CERT_FILE \
                                --user $admin_name:$admin_pwd \
                                $CONJUR_APPLIANCE_URL/authn/users/login)

        local response=$(curl -s \
                        --cacert $CONJUR_CERT_FILE  \
                        --data $access_token \
                        $CONJUR_APPLIANCE_URL/authn/users/$admin_name/authenticate)
        ADMIN_SESSION_TOKEN=$(echo -n $response| base64 | tr -d '\r\n')

}

################
# URLIFY - converts '/' and ':' in input string to hex equivalents
# in: $1 - string to convert
# out: URLIFIED - converted string in global variable
urlify() {
	local str=$1; shift
	str=$(echo $str | sed 's= =%20=g') 
	str=$(echo $str | sed 's=/=%2F=g') 
	str=$(echo $str | sed 's=:=%3A=g') 
	str=$(echo $str | sed 's=+=-=g')   # added as hack to change + to - in timezone offset in linux date string
	URLIFIED=$str
}

################  MAIN   ################
# HOST FACTORY TOKEN CREATE a new HF token with a defined expiration date
# $1 - host factory id
# $2 - dur time - hf token lifespan in seconds
hf_token_create() {
        local hf_id=$1; shift
        local dur_time_secs=$1; shift

        local token_exp_time=$(eval $DATE_SPEC)
	urlify $token_exp_time
	token_exp_time=$URLIFIED
        printf "Token exp time= %s\n" $token_exp_time

        CONJUR_HOST_FACTORY_TOKEN=$( curl \
	 -s \
         --cacert $CONJUR_CERT_FILE \
         --request POST \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
         $CONJUR_APPLIANCE_URL/host_factories/{$hf_id}/tokens?expiration=$token_exp_time \
         | jq -r '.[] | .token')
}

################
# HOST FACTORY SHOW - show info about host factory including all associated tokens
hf_show() {
        local hf_id=$1; shift

	printf "\nHost factory %s:\n" $hf_id
	curl \
	-s \
	--cacert $CONJUR_CERT_FILE \
	--header "Content-Type: application/json" \
	--header "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
	$CONJUR_APPLIANCE_URL/host_factories/{$hf_id} \
	| jq -r ' .tokens | .[] '
}

################
# HOST FACTORY TOKEN REVOKE (delete) the host factory token
hf_token_revoke() {
        local hf_token=$1; shift
        curl \
         -s \
         --cacert $CONJUR_CERT_FILE \
         --request DELETE \
         -H "Content-Type: application/json" \
         -H "Authorization: Token token=\"$ADMIN_SESSION_TOKEN\"" \
         $CONJUR_APPLIANCE_URL/host_factories/tokens/$hf_token
}


# authenticate (login) user
user_authn  # get admin session token based on user name and password

urlify $HOST_FACTORY_NAME
HOST_FACTORY_NAME=$URLIFIED

hf_show $HOST_FACTORY_NAME
# create a host factory token
hf_token_create $HOST_FACTORY_NAME $HF_TIMEOUT
printf "\nHF token is: %s\n" $CONJUR_HOST_FACTORY_TOKEN
#update application env variables with generated hf token
oc login -u $openshift_user -p $openshift_pass
oc env dc insults POSTGRESQL_USER- PGPASSWORD-
oc env dc insults -e CONJUR_APPLIANCE_URL=$CONJUR_APPLIANCE_URL  -e CONJUR_HF_TOKEN=$CONJUR_HOST_FACTORY_TOKEN -e SECRET_VAR_NAME=$SECRET_VAR_NAME -e USERNAME_VAR_NAME=$USERNAME_VAR_NAME --overwrite

