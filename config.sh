#!/bin/sh
project_name="PROJECT_NAME"

directory_log=logs
directory_public=wordpress
directory_backup=backups

file_wpcli_phar=wp-cli.phar
file_wpcli_config=wp-cli.yml

site_locale=fr_FR
site_title="${project_name}"
site_url=www.domaine.com

admin_email=cyrille@gourcy.net
admin_login=cdegourcy

db_host=localhost:8889
db_name=wp_template
db_user=root
db_pass=root
db_prefix=wp_
db_charset=utf8mb4

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
${yellow}Script for ${green}${project_name}${yellow} by ${green}Cyrille de Gourcy <cyrille@gourcy.net>${normal}
${yellow}> https://cyrille.de.gourcy.net${normal}"
