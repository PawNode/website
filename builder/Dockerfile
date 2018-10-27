FROM alpine

RUN apk add go build-base git npm nodejs

VOLUME /root/go
VOLUME /root/minit
VOLUME /root/jsip

COPY run.sh /root/run.sh

ENTRYPOINT ["sh", "/root/run.sh"]


