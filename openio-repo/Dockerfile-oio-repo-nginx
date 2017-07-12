# Use an official Python runtime as a base image
FROM nginx

RUN set -ex && apt-get update && apt-get upgrade -y && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /usr/share/nginx/html/pub/repo && chown nginx.nginx /usr/share/nginx/html/pub/repo && chmod 755 /usr/share/nginx/html/pub/repo
COPY files/nginx.conf /etc/nginx/conf.d/default.conf
