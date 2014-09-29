#!/bin/bash

# this script is used to create domains


# set env variable from input file
source input.properties
DOMAIN_HOME=$DOMAIN_DIR/$DOMAIN_NAME

#check if domain alread exists
[[ -e $DOMAIN_HOME ]] && echo "domain $DOMAIN_NAME already exists, exit now" && exit


# get create_domain.py config_domain.py
./create_py.pl

# create domain
bash $WLST_PATH create_domain.py
echo "create domain finished"

# config domain
bash $WLST_PATH config_domain.py
echo "config domain finished"
