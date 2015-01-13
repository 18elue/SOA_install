#!/bin/bash

# this script is used to create and config domains


# set env variable from input file
source wls_input.properties
DOMAIN_HOME=$DOMAIN_DIR/$DOMAIN_NAME

#check if domain alread exists
#[[ -e $DOMAIN_HOME ]] && echo "domain $DOMAIN_NAME already exists, exit now" && exit

ip=$(ifconfig|grep "inet addr:"|grep -v '127.0.0.1'|awk '{print $2}'|awk -F: '{print $2}')
# create domain
if [[ $ADMIN_SERVER_ADDRESS = $ip ]]; then
    bash $WLST_PATH create_wls_domain.py
    expect cp_domain.expect
fi 

# execute other info script
replaced_ip=${ip//./_}
bash other_info_$replaced_ip.sh

sleep 10

if [[ $ADMIN_SERVER_ADDRESS = $ip ]]; then
    expect run_other_info.expect
fi 
