#!/bin/sh
. $(dirname "$0")/config.sh

echo " "
echo "---"
echo "${blue}${bold}# BACKUP WP FILES${normal}"
date="$(date +%Y-%m-%y)"
tar -zcf ${directory_backup}/${date}_${directory_public}-files.tar.gz ${directory_public}
echo "The backup file ${green}${date}_${directory_public}-files.tar.gz${normal} have been created in ${green}/${directory_backup}${normal}."
echo " "
echo "---"
echo "${blue}${bold}# BACKUP DB${normal}"
php ${file_wpcli_phar} db export ${directory_backup}/${date}_${directory_public}-db.sql
echo "The DB backup ${green}${directory_backup}/${date}_${directory_public}-db.sql${normal} have been created in ${green}/${directory_backup}${normal}."
echo "---"
