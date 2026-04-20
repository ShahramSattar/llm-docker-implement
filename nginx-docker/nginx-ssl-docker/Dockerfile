FROM nginx:alpine

# Copy nginx configurations
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/ssl_self.conf /etc/nginx/ssl_self.conf

# Copy self-signed certificates
COPY ssl/self-signed/ /etc/nginx/ssl/self-signed/

# Copy HTML content
COPY html/ /usr/share/nginx/html/

# Copy common configurations
COPY nginx/common/ /etc/nginx/common/


# Remove default nginx config
RUN rm -f /etc/nginx/conf.d/default.conf

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]