FROM node:10-alpine

USER root

RUN apk add --no-cache make gcc g++
RUN apk add --no-cache python && \
    python -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip install --upgrade pip setuptools && \
    rm -r /root/.cache
RUN apk add --no-cache git

RUN mkdir -p /src

COPY . /src
WORKDIR /src

RUN npm install -g npm && rm -rf node_modules && npm install && npm run build

CMD ["npm","run","start-demo"]