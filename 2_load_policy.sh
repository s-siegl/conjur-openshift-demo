#!/bin/bash


red=`tput setaf 1`
orange=`tput setaf 166`
green=`tput setaf 2`
blue=`tput setaf 4`
reset=`tput sgr0`

POLICY_FILE="policies/policy.yml"
CONJURRC="~/.conjurrc"
CONJUR_APPLIANCE_URL="https://conjur-appliance"
CONJUR_ORG="orgaccount"


echo "${blue}Configure conjur CLI and load policies${reset}"
rm -f ~/.conjurrc ~/conjur*
conjur init -h $CONJUR_APPLIANCE_URL $CONJUR_ORG
echo "${orange}Installing conjur-cli policy plugin ...${reset}"
conjur plugin install policy
echo "${orange}Enter conjur admin password${reset}"
conjur authn login admin
output=$(conjur policy load --as-group security_admin $POLICY_FILE | tail -1)
user_pass=$(echo $output | jq '.["orgaccount:user:jam"]')
conjur auth logout
echo "${orange}Enter jam password: ${blue} $user_pass ${reset}"
conjur authn login jam
conjur user update_password -p "password"
echo "${orange}Passsword for jam is now: password${reset}"
echo "${green}Done${reset}"

echo "${blue}Set value to secrets${reset}"
conjur variable values add insultapp/database/username "insult"
conjur variable values add insultapp/database/password "insult"
conjur variable values add insultapp/database/name "insults"
echo "${green}Done${reset}"

