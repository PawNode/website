#!/bin/sh
set -e

mkdir -p /root/go /root/jsip /root/minit

git_get() {
	git clone "https://github.com/Doridian/$1" 2>/dev/null || (cd "$1" && git pull)
}

cd /root
git_get jsip
git_get minit

export GOPATH=/root/go

cd /root/jsip
rm -f src/main.ts
cp /root/jsip_main.ts src/main.ts
rm -rf dist
npm i
npm run build
rm -rf dist/test
(find ./dist -type f -name "*.js" -exec echo "add_header Link \"</{}>; rel=preload; as=script\";" \; | sed s~/./~/~) > "/root/jsip/nginx_push.conf"

cd /root/go
rm -rf /root/go/bin
go get -d -u github.com/Doridian/wsvpn/server
go install github.com/Doridian/wsvpn/server

cd /root/minit
./compile.sh

# docker run --cap-add=NET_ADMIN --device=/dev/net/tun --entrypoint /bin/sh --rm -it doridian/website

