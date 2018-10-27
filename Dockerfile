FROM alpine

COPY jsip/dist/ /var/www/html/dist/
COPY jsip_app/index.html /var/www/html/

COPY site/ /var/www/wsvpn/

COPY conf/nginx-site.conf /etc/nginx/conf.d/site.conf
COPY conf/nginx-push.conf /etc/nginx/push.conf

