#!/bin/sh
. $(dirname "$0")/config.sh

echo "---"

echo "Compiling of SASS files:"

sass ${directory_public}/wp-content/themes/${theme_child_name}/assets/scss${project_slug}.scss:${directory_public}/wp-content/themes/${theme_child_name}/assets/css/${project_slug}.css
echo "Regenerated ${project_slug}.css"

sass ${directory_public}/wp-content/themes/${theme_child_name}/assets/scss/${project_slug}.scss:${directory_public}/wp-content/themes/${theme_child_name}/assets/css/${project_slug}.min.css --style compressed
echo "Regenerated ${project_slug}.min.css"

echo "---"

echo "Done";
