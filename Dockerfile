FROM nginx:alpine
COPY target/*.war /usr/share/nginx/html/
