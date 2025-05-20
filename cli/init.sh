#!/bin/sh
set -euo pipefail

# Chargement de la config
CONFIG_FILE="$(dirname "$0")/config.sh"
[ -f "$CONFIG_FILE" ] && . "$CONFIG_FILE" || { echo "Missing config: $CONFIG_FILE"; exit 1; }

echo ""
echo "---"
echo "${blue}${bold}# SÉCURITÉ WP-CLI (SHA512)${normal}"

TMP_PHAR="wp-cli.phar"
TMP_SHA="wp-cli.phar.sha512"

# Télécharger le phar et sa signature
curl -O -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/$TMP_PHAR
curl -O -L https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/$TMP_SHA

# Vérification de la signature
if echo "$(cat $TMP_SHA)  $TMP_PHAR" | sha512sum -c -; then
    mv $TMP_PHAR "$file_wpcli_phar"
    chmod 700 "$file_wpcli_phar"
    echo "✅ WP-CLI vérifié et installé : ${green}$file_wpcli_phar${normal}"
else
    echo "${red}[!] ERREUR : Signature WP-CLI invalide${normal}"
    rm -f $TMP_PHAR $TMP_SHA
    exit 1
fi

rm -f $TMP_SHA


echo "${blue}${bold}# COMPLETION WP-CLI${normal}"
curl -o "${file_wpcli_completion}" -L https://github.com/wp-cli/wp-cli/raw/master/utils/wp-completion.bash
chmod 700 "${file_wpcli_completion}"
echo "Complétion installée : ${green}${file_wpcli_completion}${normal}"

echo ""
echo "---"
echo "${blue}${bold}# FICHIER DE CONFIG WP-CLI${normal}"
if [ ! -f "${file_wpcli_config}" ]; then
    echo "path: ${directory_public}" > "${file_wpcli_config}"
    chmod 700 "${file_wpcli_config}"
    echo "Config créé : ${green}${file_wpcli_config}${normal}"
else
    chmod 700 "${file_wpcli_config}"
    echo "Config existant : ${green}${file_wpcli_config}${normal}"
fi

# Fonction pour sécuriser un dossier
securise_dossier() {
    local dir="$1"
    local label="$2"
    if [ -d "$dir" ]; then
        find "$dir" -type d -exec chmod 755 {} \;
        find "$dir" -type f -exec chmod 644 {} \;
        echo "${label} : droits appliqués (755/644)"
    else
        echo "${red}Dossier $dir inexistant${normal}, création..."
        mkdir -p -m 755 "$dir"
        echo "${label} : créé avec droits 755"
    fi
}

echo ""
echo "---"
echo "${blue}${bold}# DROITS PUBLIC${normal}"
securise_dossier "${directory_public}" "Dossier public"
[ -f "${directory_public}/wp-config.php" ] && chmod 444 "${directory_public}/wp-config.php"
[ -f "${directory_public}/.htaccess" ] && chmod 444 "${directory_public}/.htaccess"

echo ""
echo "---"
echo "${blue}${bold}# LOGS & BACKUPS${normal}"
securise_dossier "${directory_log}" "Logs"
securise_dossier "${directory_backup}" "Backups"

echo "---"