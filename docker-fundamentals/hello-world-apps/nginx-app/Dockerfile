FROM nginx:1.30-alpine

# Replace the stock server block with ours, then the stock welcome page with ours.
COPY default.conf /etc/nginx/conf.d/default.conf
COPY html/ /usr/share/nginx/html/

EXPOSE 80
# CMD is inherited from the base image: nginx -g 'daemon off;'
