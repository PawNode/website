#!/bin/sh
set -e

WDIR="$(pwd)"

mkdir -p gopath

git_get() {
	git clone "https://github.com/Doridian/$1" 2>/dev/null || (cd "$1" && git pull)
}

git_get jsip
git_get minit

rm -f jsip/src/main.ts
cp jsip_app/main.ts jsip/src/main.ts

BUILDER_TMP="website-builder-tmp"
docker build -t doridian/website-builder builder
docker run --rm --name "$BUILDER_TMP" -v "$WDIR/gopath:/root/go" -v "$WDIR/minit:/root/minit" -v "$WDIR/jsip:/root/jsip" doridian/website-builder

docker build -t doridian/website .

