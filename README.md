# WPSTARTER KIT

## CLI commands

Be sure to have good rights access on `cli` directory, and be able to run shell scripts. Use `chmod -R 755 cli` if you don't be able to.

### 1. cli/config.sh

Rename file `cli/config.sample.sh` to `cli/config.sh` by usinh:

```
cp cli/config.sample.sh cli/config.sh
```

Then, fill all settings withs data of the project in this file.

### 2. cli/init.sh

First command to use to initialize the directories and the rights on them before installing WordPress.

Form the root directory, just run:

```
cli/init.sh
```

### 3. cli/install-wordpress.sh

```
cli/install-wordpress.sh
```

### 4. cli/backup.sh

Command used to make an archives of all public directory (default `wordpress/`) where WordPress is installed & make a dump of the database.

Both files are store in backup directory (default `save/`).

```
cli/backup.sh
```

### 5. cli/compile-sass.sh

Only usefull during developpement, this commande run the `sass` command to generate `css` files in the theme directory.

```
cli/compile-sass.sh
```

## WP-CLI commands

### Install some usefull plugins

```
wp plugin install elementor --activate
wp plugin install code-snippets --activate
wp plugin install enable-media-replace --activate
wp plugin install loco-translate --activate
wp plugin install pro-elements --activate
wp plugin install redirection --activate
wp plugin install google-site-kit --activate
wp plugin install duplicate-post --activate
wp plugin install wordpress-seo --activate
```

## PRO Elements

This plugin enables GPL features of Elementor Pro: widgets, theme builder, dynamic colors and content, forms & popup builder, and more.

```
git clone https://github.com/proelements/proelements
```
