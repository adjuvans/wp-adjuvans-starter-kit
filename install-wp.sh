#!/bin/sh

source config.sh

echo "${standout}

#
#   ██████╗██████╗  ██████╗     ██╗      █████╗ ██████╗ ███████╗
#  ██╔════╝██╔══██╗██╔════╝     ██║     ██╔══██╗██╔══██╗██╔════╝
#  ██║     ██║  ██║██║  ███╗    ██║     ███████║██████╔╝███████╗
#  ██║     ██║  ██║██║   ██║    ██║     ██╔══██║██╔══██╗╚════██║
#  ╚██████╗██████╔╝╚██████╔╝    ███████╗██║  ██║██████╔╝███████║
#   ╚═════╝╚═════╝  ╚═════╝     ╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝
#
${normal}
${yellow}Install script for WordPress for project ${green}${project_name}
${yellow}> Cyrille de Gourcy ${green}<cyrille@gourcy.net>${normal}
${yellow}> https://cyrille.de.gourcy.net${normal}"


echo "${blue}${bold}# WORDPRESS${normal}"

if [ ! -d "${directory_public}" ]; then
    echo "---"
    echo "${yellow}1/3 Downloading WordPress${normal}"
    php wp-cli.phar core download --locale=${site_locale}

    echo "${yellow}2/3 Generate config file${normal}"
    php wp-cli.phar config create --dbhost=${db_host} --dbname=${db_name} --dbuser=${db_user} --dbpass=${db_pass} --dbprefix=${db_prefix} --dbcharset=${db_charset} --locale=${site_locale}

    echo "${yellow}3/3 Installing WordPress${normal}"
    php wp-cli.phar core install --url=${site_url} --title=${site_title} --admin_user=${admin_login} --admin_email=${admin_email}
    echo "---"
else
    echo "---"
    echo "WordPress is already installed"
    echo "---"
fi

if [ ! -d "${directory_public}" ]; then
    echo "---"
    echo "Installing plugins"
    php wp-cli.phar plugin install query-monitor --activate
    php wp-cli.phar plugin install maintenance --activate
    php wp-cli.phar plugin install loco-translate --activate
    php wp-cli.phar plugin install contact-form-7 --activate
    php wp-cli.phar plugin install redirection --activate
    php wp-cli.phar plugin install duplicate-post --activate
    php wp-cli.phar plugin install wordpress-seo --activate
    echo "---"
fi
