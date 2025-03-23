ARG PHP_VERSION=8.0
ARG NODE_VERSION=16
ARG NGINX_VERSION=1.24


######### NODE CONFIG
FROM node:${NODE_VERSION}-alpine AS node

WORKDIR /srv/app

RUN apk update; \
    apk add yarn;
RUN apk add --no-cache --virtual .build-deps alpine-sdk python3

# Install copy-webpack-plugin before install/build
COPY package.json yarn.lock ./

# Now copy the rest of the build context
COPY tsconfig.json tslint.json webpack.config.js ./
COPY src src/
COPY styles styles/
COPY templates templates/
COPY bin bin/
COPY data data/
COPY www/assets www/assets

RUN set -eux; \
	yarn install; \
	yarn cache clean; \
    yarn build

RUN apk del .build-deps

COPY ./.docker/node/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]
CMD ["yarn", "start"]


######### PHP CONFIG
FROM php:${PHP_VERSION}-fpm-alpine AS php

# Match NGINX root
WORKDIR /var/www/www

# Copy the project’s www folder (index.php lives here)
COPY www/ .

# In the PHP stage
COPY --from=node /srv/app/www/assets /var/www/www/assets


EXPOSE 9000

COPY ./.docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

ENTRYPOINT ["docker-entrypoint"]
CMD ["php-fpm"]


######### NGINX CONFIG
FROM nginx:${NGINX_VERSION}-alpine AS nginx

# Match the NGINX root path
WORKDIR /var/www/www

# Copy NGINX config
COPY .docker/nginx/conf.d/domain.conf /etc/nginx/conf.d/default.conf

# Copy static assets and PHP entrypoint into the directory NGINX serves from
COPY --from=node /srv/app/www/assets ./assets
COPY --from=php /var/www/www/index.php ./index.php


