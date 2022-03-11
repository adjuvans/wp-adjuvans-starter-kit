#!/bin/sh
. $(dirname "$0")/config.sh

echo " "
echo "---"
echo "${blue}${bold}# WordPress Installer${normal}"

wp core download
wp config create --dbhost=${db_host} --dbname=${db_name} --dbuser=${db_user} --dbpass=${db_pass} --dbprefix=${db_prefix} --locale=${site_locale}

echo "---"
