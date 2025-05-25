FROM nginx:alpine

#Clonar la app 2048 directamente
RUN apk add --no-cache git && \
 git clone https://github.com/gabrielecirulli/2048.git /usr/share/nginx/html && \
 rm -rf /usr/share/nginx/html/.git

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
