#!/bin/sh

WDIR="$(pwd)"

git clone https://github.com/Doridian/jsip 2>/dev/null || (cd jsip && git pull)

rm -f jsip/src/main.ts
cp jsip_app/main.ts jsip/src/main.ts

cd jsip
rm -rf dist
npm i
npm run build

cd "$WDIR"

docker build -t doridian/website .

