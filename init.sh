#!/bin/sh

# WordPress install script - by Cyrille de Gourcy
# Make sure you have WP-CLI installed on environment and up to date

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
${yellow}Init script for ${green}${project_name}
${yellow}> Cyrille de Gourcy ${green}<cyrille@gourcy.net>${normal}
${yellow}> https://cyrille.de.gourcy.net${normal}"

echo " "
echo "---"
echo "${blue}${bold}# WP-CLI${normal}"
if [ -e "${file_wpcli_phar}" ]; then
    chmod 700 ${file_wpcli_phar}
    echo "WP-CLI ${green}${file_wpcli_phar}${normal} have been maked executable."
else
    echo "Installing WP-CLI"
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod 700 ${file_wpcli_phar}
    echo "WP-CLI ${green}${file_wpcli_phar}${normal} have been created & maked executable."
fi

# Create config file for WP-CLI
if [ -e "${file_wpcli_config}" ]; then
    chmod 700 ${file_wpcli_config}
    echo "Config file ${green}${file_wpcli_config}${normal} have been maked executable."
else
    echo "path: ${directory_public}" | tee ${file_wpcli_config}
    chmod 700 ${file_wpcli_config}
    echo "Config file ${green}${file_wpcli_config}${normal} have been created & maked executable."
fi

# Get WordPress Sources
if [ ! -d "${directory_public}" ]; then
    echo " "
    echo "---"
    echo "${blue}${bold}# WORDPRESS${normal}"
    echo "Installing WordPress"
    php wp-cli.phar core download --locale=fr_FR

    echo "Installing plugins"
    php wp-cli.phar plugin install query-monitor
    php wp-cli.phar plugin install maintenance
    php wp-cli.phar plugin install loco-translate
    php wp-cli.phar plugin install contact-form-7
    php wp-cli.phar plugin install redirection
    php wp-cli.phar plugin install duplicate-post
    php wp-cli.phar plugin install wordpress-seo
fi

echo " "
echo "---"
echo "${blue}${bold}# PUBLIC DIRECTORY${normal}"
# Change rights on files & directories
if [ -d "${directory_public}" ]; then
    # change rights on directories
    find ${directory_public} -type d -exec chmod -R 755 {} \;
    echo "Rights of the directories in ${green}/${directory_public}${normal} have been changed to ${green}755${normal}."


    # change rights on files
    find ${directory_public} -type f -exec chmod -R 644 {} \;
    echo "Rights of the files in ${green}/${directory_public}${normal} have been changed to ${green}644${normal}."
else
    echo "${red}The directory /${directory_public} doesn't exist!${normal}"
fi

echo " "
echo "---"
echo "${blue}${bold}# LOGS DIRECTORY${normal}"
# Change rights on files & directories
if [ -d "${directory_log}" ]; then
    # change rights on directories
    chmod 755 ${directory_log}
    echo "Rights of the directories ${green}/${directory_log}${normal} have been changed to ${green}755${normal}."
else
    echo "${red}The directory /${directory_log} doesn't exist!${normal}"
    echo "I'll create it."
    mkdir -m 755 ${directory_log}
    echo "The directory ${green}/${directory_log}${normal} have been created in ${green}755${normal} mode."
fi

echo " "
echo "---"
echo "${blue}${bold}# BACKUPS DIRECTORY${normal}"
# Change rights on files & directories
if [ -d "${directory_backup}" ]; then
    # change rights on directories
    find ${directory_backup} -type d -exec chmod -R 755 {} \;
    echo "Rights of the directories in ${green}/${directory_backup}${normal} have been changed to ${green}755${normal}."
else
    echo "${red}The directory /${directory_backup} doesn't exist!${normal}"
    echo "I'll create it."
    mkdir -m 755 ${directory_backup}
    echo "The directory ${green}/${directory_backup}${normal} have been created in ${green}755${normal} mode."
fi
echo "---"
