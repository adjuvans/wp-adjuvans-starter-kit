#!/bin/sh
. $(dirname "$0")/config.sh

echo " "
echo "---"
echo "${blue}${bold}# WP-CLI INSTALL${normal}"
# Install or update WP-CLI
if [ -e "${file_wpcli_phar}" ]; then
    chmod 700 ${file_wpcli_phar}
    php ${file_wpcli_phar} cli update
    echo "WP-CLI file ${green}${file_wpcli_phar}${normal} have been updated & maked executable."
else
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod 700 ${file_wpcli_phar}
    echo "WP-CLI file ${green}${file_wpcli_phar}${normal} have been created & maked executable."
fi

echo "${blue}${bold}# WP-CLI COMPLETION${normal}"
# Install or update WP-CLI COMPLETION
curl -O https://github.com/wp-cli/wp-cli/raw/master/utils/wp-completion.bash
chmod 700 ${file_wpcli_completion}
echo "WP-COMPLETION file ${green}${file_wpcli_completion}${normal} have been created & maked executable."

echo " "
echo "---"
echo "${blue}${bold}# WP-CLI CONFIG FILE${normal}"
# Create config file for WP-CLI
if [ -e "${file_wpcli_config}" ]; then
    chmod 700 ${file_wpcli_config}
    echo "Config file ${green}${file_wpcli_config}${normal} have been maked executable."
else
    echo "path: ${directory_public}" | tee ${file_wpcli_config}
    chmod 700 ${file_wpcli_config}
    echo "Config file ${green}${file_wpcli_config}${normal} have been created & maked executable."
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

    chmod 444 ${directory_public}/wp-config.php
    echo "Rights of the file in ${green}/${directory_public}/wp-config.php${normal} have been changed to ${green}444${normal}."

    chmod 444 ${directory_public}/.htaccess
    echo "Rights of the file in ${green}/${directory_public}/.htaccess${normal} have been changed to ${green}444${normal}."
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
