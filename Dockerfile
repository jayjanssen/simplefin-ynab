FROM node:10-alpine
MAINTAINER jay.janssen@gmail.com

USER root

RUN npm install -g nodemon coffeescript

WORKDIR /app

COPY package.json package-lock.json /app/
RUN npm install

COPY sync.coffee /app

USER node

CMD /app/sync.coffee
