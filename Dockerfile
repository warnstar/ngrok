FROM golang:1.9

COPY ngrok /go/src/ngrok

WORKDIR /go/src/ngrok

ENV TUNNEL_DOMAIN a.example.com

RUN openssl genrsa -out rootCA.key 2048
RUN openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$TUNNEL_DOMAIN" -days 5000 -out rootCA.pem
RUN openssl genrsa -out device.key 2048
RUN openssl req -new -key device.key -subj "/CN=$TUNNEL_DOMAIN" -out device.csr
RUN openssl x509 -req -in device.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out device.crt -days 5000

RUN cp rootCA.pem assets/client/tls/ngrokroot.crt
RUN cp device.crt assets/server/tls/snakeoil.crt
RUN cp device.key assets/server/tls/snakeoil.key

RUN make release-server
RUN make release-client && GOOS=windows GOARCH=amd64 make release-client

EXPOSE 80 443 4443
#CMD "/go/src/ngrok/bin/ngrokd -domain="$TUNNEL_DOMAIN" -httpAddr=":80" -httpsAddr=":443""

ENTRYPOINT /go/src/ngrok/bin/ngrokd -domain="$TUNNEL_DOMAIN" -httpAddr=":80" -httpsAddr=":443"