#!/bin/sh

WDIR="$(pwd)"

git clone https://github.com/Doridian/jsip 2>/dev/null || (cd jsip && git pull)

rm -f jsip/src/main.ts
cp jsip_app/main.ts jsip/src/main.ts

cd jsip
rm -rf dist
npm i
npm run build
rm -rf dist/test

(find ./dist -type f -name "*.js" -exec echo "add_header Link \"</{}>; rel=preload; as=script\";" \; | sed s~/./~/~) > "$WDIR/conf/nginx-push.conf"

cd "$WDIR"

docker build -t doridian/website .

