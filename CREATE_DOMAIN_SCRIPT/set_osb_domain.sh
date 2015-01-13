#!/bin/bash

# this script is used to create and config domains


# set env variable from input file
source wls_input.properties
DOMAIN_HOME=$DOMAIN_DIR/$DOMAIN_NAME

#check if domain alread exists
#[[ -e $DOMAIN_HOME ]] && echo "domain $DOMAIN_NAME already exists, exit now" && exit

ip=$(ifconfig|grep "inet addr:"|grep -v '127.0.0.1'|awk '{print $2}'|awk -F: '{print $2}')
# create domain
if [[ $ADMIN_SERVER_ADDRESS = $ip ]] && [[ $DOMAIN_TYPE = OSB ]]; then
    bash $WLST_PATH create_osb_domain.py
    expect cp_domain.expect
fi 

# start the osb admin server
cd $DOMAIN_HOME/bin
nohup ./startWebLogic.sh &

