#!/usr/bin/env zsh

# run bulma build
echo "building bulma assets"
sass --style expanded --load-path=node_modules/bulma custom.scss ../css/custom.css
rm ../css/custom.css.map

# run tailwind build
echo "building tailwind assets"
cd ..
tailwindcss --config tailwind.config.js --input css/app.css --output ../priv/static/assets/app.css
