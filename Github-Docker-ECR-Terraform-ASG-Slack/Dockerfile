# Use the official Nginx base image
FROM nginx:alpine

# Remove the default Nginx index page
RUN rm -rf /usr/share/nginx/html/*

# Copy your custom index.html into the Nginx web directory
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80 inside the container
EXPOSE 80

