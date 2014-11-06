#!/bin/bash

# this script is used to create and config domains


# set env variable from input file
source wls_input.properties
DOMAIN_HOME=$DOMAIN_DIR/$DOMAIN_NAME

#check if domain alread exists
[[ -e $DOMAIN_HOME ]] && echo "domain $DOMAIN_NAME already exists, exit now" && exit

# create domain
bash $WLST_PATH create_wls_domain.py 

# execute other info script
ip=$(hostname -i)
ip=${ip//./_}
bash other_info_$ip.sh
