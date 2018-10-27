#!/bin/sh
set -e

export GOPATH=/root/go

cd /root/jsip
rm -rf dist
npm i
npm run build
rm -rf dist/test
(find ./dist -type f -name "*.js" -exec echo "add_header Link \"</{}>; rel=preload; as=script\";" \; | sed s~/./~/~) > "/root/jsip/nginx_push.conf"

cd /root/go
rm -rf /root/go/bin
go get -u github.com/Doridian/wsvpn/server
go install github.com/Doridian/wsvpn/server

cd /root/minit
./compile.sh

