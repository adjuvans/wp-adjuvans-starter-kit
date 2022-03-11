#!/bin/sh
. $(dirname "$0")/config.sh

echo " "
echo "---"
echo "${blue}${bold}# WordPress Installer${normal}"

#wp core download
wp config create --dbhost=${db_host} --dbname=${db_name} --dbuser=${db_user} --dbprefix=${db_prefix} --locale=${site_locale} --dbpass=${db_pass} --extra-php <<PHP
define( 'WP_DEBUG_DISPLAY', false );
define( 'WP_DEBUG_LOG', '../logs/'.date('Y-m-d').'_wp-errors.log' );
PHP
wp core install --url=${site_url} --title=${site_title} --admin_user=${admin_login} --admin_email=${admin_email}
echo "---"
