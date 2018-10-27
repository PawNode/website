#!/bin/sh
set -e

/sbin/tunctl -t tap-ws0 -u wsvpn -g wsvpn
/sbin/ifconfig tap-ws0 10.0.0.1 netmask 255.0.0.0 mtu 1280 up

exec su -s /bin/sh - wsvpn -c "/opt/wsvpn/server --listen=127.0.0.1:9000 --subnet=10.0.0.0/24 --tap-noconf --tap --tap-name tap-ws0 --tap-persist --tap-no-ifconfig"


