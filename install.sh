#!/bin/sh

# WordPress install script - by Cyrille de Gourcy
# Make sure you have WP-CLI installed on environment and up to date

project_name=<PROJECT NAME>
directory_log=logs
directory_public=wordpress
directory_backup=backups
file_wpcli_config=wp-cli.yml

# check if stdout is a terminal...
if test -t 1; then
    # see if it supports colors...
    ncolors=$(tput colors)
    if test -n "$ncolors" && test $ncolors -ge 8; then
        bold="$(tput bold)"
        underline="$(tput smul)"
        standout="$(tput smso)"
        normal="$(tput sgr0)"
        black="$(tput setaf 0)"
        red="$(tput setaf 1)"
        green="$(tput setaf 2)"
        yellow="$(tput setaf 3)"
        blue="$(tput setaf 4)"
        magenta="$(tput setaf 5)"
        cyan="$(tput setaf 6)"
        white="$(tput setaf 7)"
    fi
fi

clear

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
${yellow}Install script for ${green}${project_name}
${yellow}> Cyrille de Gourcy ${green}<cyrille@gourcy.net>${normal}
${yellow}> https://cyrille.de.gourcy.net${normal}"


echo " "
echo "---"
echo "${blue}${bold}# WP-CLI${normal}"
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

echo " "
echo "---"
echo "${blue}${bold}# BACKUPS DIRECTORY${normal}"
# Change rights on files & directories
if [ -d "${directory_backup}" ]; then
    # change rights on directories
    chmod 755 ${directory_backup}
    echo "Rights of the directory ${green}/${directory_backup}${normal} have been changed."
else
    echo "${red}The directory /${directory_backup} doesn't exist!${normal}"
    echo "${red}Please check the repository of the project.${normal}"
fi
echo "---"
