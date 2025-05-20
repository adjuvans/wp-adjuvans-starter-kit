#!/bin/sh
CONFIG_FILE="$(dirname "$0")/config.sh"

if [ -f "$CONFIG_FILE" ]; then
    echo "Fichier de config trouvé : $CONFIG_FILE"
    . "$CONFIG_FILE"
    exit 0
fi

echo "Fichier de config manquant."
echo "Créons ensemble un nouveau fichier config.sh..."
echo ""

# Saisie interactive
read -p "Nom de la base de données : " db_name
read -p "Utilisateur DB : " db_user
read -s -p "Mot de passe DB : " db_pass; echo
read -p "Hôte DB [localhost] : " db_host
db_host=${db_host:-localhost}

read -p "Préfixe des tables [wp_] : " db_prefix
db_prefix=${db_prefix:-wp_}

read -p "Locale du site [fr_FR] : " site_locale
site_locale=${site_locale:-fr_FR}

read -p "URL du site (ex: https://monsite.test) : " site_url
read -p "Titre du site : " site_title

read -p "Login admin WP : " admin_login
read -s -p "Mot de passe admin : " admin_pass; echo
read -p "Email admin : " admin_email

# Création du fichier
cat <<EOF > "$CONFIG_FILE"
#!/bin/sh

# Couleurs (affichage)
red=\$(tput setaf 1)
green=\$(tput setaf 2)
blue=\$(tput setaf 4)
bold=\$(tput bold)
normal=\$(tput sgr0)

# Répertoires
directory_public="./public"
directory_log="./logs"
directory_backup="./backups"

# WP-CLI
file_wpcli_phar="./wp-cli.phar"
file_wpcli_completion="./wp-completion.bash"
file_wpcli_config="./wp-cli.yml"

# DB
db_name="${db_name}"
db_user="${db_user}"
db_pass="${db_pass}"
db_host="${db_host}"
db_prefix="${db_prefix}"

# Site WP
site_locale="${site_locale}"
site_url="${site_url}"
site_title="${site_title}"
admin_login="${admin_login}"
admin_pass="${admin_pass}"
admin_email="${admin_email}"
EOF

chmod 700 "$CONFIG_FILE"
echo "✅ Fichier ${green}config.sh${normal} généré avec succès."