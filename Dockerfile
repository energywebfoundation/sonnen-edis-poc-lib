FROM node:11-alpine

USER root

RUN apk add --no-cache make gcc g++
RUN apk add --no-cache python && \
    python -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip install --upgrade pip setuptools && \
    rm -r /root/.cache
RUN apk add --no-cache git

WORKDIR /
COPY src/docker/start.sh /start.sh

CMD ["/bin/sh","start.sh"]