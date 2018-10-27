FROM alpine

RUN apk add --no-cache nginx shadow dhcp unbound
RUN groupadd -g 1000 wsvpn && useradd -u 1000 -g 1000 wsvpn && mkdir -p /home/wsvpn && chown wsvpn:wsvpn /home/wsvpn

COPY conf/minit_services /minit/services
COPY conf/minit_onboot /minit/onboot
COPY minit/minit /minit/minit

COPY jsip/dist/ /var/www/html/dist/
COPY jsip_app/index.html /var/www/html/

COPY site/ /var/www/wsvpn/

COPY conf/nginx_site.conf /etc/nginx/conf.d/default.conf
COPY jsip/nginx_push.conf /etc/nginx/push.conf

COPY conf/wsvpn_start.sh /opt/wsvpn/start.sh
COPY gopath/bin/server /opt/wsvpn/server

COPY conf/dhcpd.conf /etc/dhcp/dhcpd.conf
COPY conf/unbound.conf /etc/unbound/master.conf

ENTRYPOINT ["/minit/minit"]

