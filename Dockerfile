FROM nginx:alpine
COPY site/target/*.war /usr/share/nginx/html/

