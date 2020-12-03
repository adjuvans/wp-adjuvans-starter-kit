#!/bin/sh

source config.sh

echo " "
echo "---"
echo "${blue}${bold}# BACKUP WP FILES${normal}"
date="$(date +%Y-%m-%y)"
tar -zcf ${directory_backup}/${date}_${directory_public}.tar.gz ${directory_public}
echo "The backup file ${green}${date}_${directory_public}-files.tar.gz${normal} have been created in ${green}/${directory_backup}${normal}."
echo " "
echo "---"
echo "${blue}${bold}# BACKUP DB${normal}"
wp db export ${directory_backup}/${date}_${directory_public}-files.sql
echo "The DB backup ${green}${directory_backup}/${date}_${directory_public}-db.sql${normal} have been created in ${green}/${directory_backup}${normal}."
echo "---"
