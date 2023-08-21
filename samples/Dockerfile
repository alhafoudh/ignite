FROM gliderlabs/herokuish:latest-22
COPY . /tmp/app

RUN /build && rm -Rf /tmp/app

ENTRYPOINT [ "/start" ]

CMD [ "web" ]