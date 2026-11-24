# epitech.elliotmoreau.fr: the static site, served by nginx.
FROM nginx:1.29-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY index.html style.css main.js favicon.svg /usr/share/nginx/html/
COPY assets /usr/share/nginx/html/assets
COPY fonts /usr/share/nginx/html/fonts
EXPOSE 80
