FROM alpine

COPY jsip/dist/ /var/www/html/dist/
COPY jsip_app/index.html /var/www/html/

