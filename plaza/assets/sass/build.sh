#!/usr/bin/env zsh

# run bulma build
echo "building bulma assets"
node-sass --output-style expanded --include-path=node_modules/bulma custom.scss ../css/custom.css

# run tailwind build
echo "building tailwind assets"
tailwindcss -c ../tailwind.config.js -i ../css/app.css -i ../css/custom.css -o ../../priv/static/assets/app.css

echo "syncing with elixir priv"
# copy to priv (just incase elixir watcher picks it up)
cp ./../css/custom.css ./../../priv/static/assets/
