FROM doridian/alpine-builder as builder

COPY builder.sh /root/builder.sh
COPY jsip_app/main.ts /root/jsip_main.ts

RUN /root/builder.sh

FROM doridian/alpine-minit
MAINTAINER Doridian

RUN apk add --no-cache nginx shadow dhcp unbound iptables ip6tables
RUN groupadd -g 1000 wsvpn && useradd -u 1000 -g 1000 wsvpn && mkdir -p /home/wsvpn && chown wsvpn:wsvpn /home/wsvpn

COPY conf/minit_services /minit/services
COPY conf/minit_onboot /minit/onboot
COPY conf/iptables.v4 /minit/iptables.v4
COPY conf/iptables.v6 /minit/iptables.v6

COPY conf/nginx_site.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /root/jsip/nginx_push.conf /etc/nginx/push.conf

COPY conf/wsvpn_start.sh /opt/wsvpn/start.sh
COPY --from=builder /root/go/bin/server /opt/wsvpn/server

COPY conf/dhcpd.conf /etc/dhcp/dhcpd.conf
COPY conf/unbound.conf /etc/unbound/master.conf

COPY --from=builder /root/jsip/dist/ /var/www/html/dist/
COPY jsip_app/index.html /var/www/html/

COPY site/ /var/www/wsvpn/

EXPOSE 80 9000

