# Multi-stage build for Flutter Web App
# Stage 1: Build Flutter Web
FROM cirrusci/flutter:3.19.0 AS build-stage

WORKDIR /app

# Copy pubspec files and get dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build arguments for API configuration
ARG API_BASE_URL=https://docextract-backend.up.railway.app
ARG WS_URL=wss://docextract-backend.up.railway.app/ws/documents

# Build Flutter web app with API configuration
RUN flutter build web --release \
    --dart-define=API_BASE_URL=${API_BASE_URL} \
    --dart-define=WS_URL=${WS_URL}

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built web app from build stage
COPY --from=build-stage /app/build/web /usr/share/nginx/html

# Create custom nginx configuration for Flutter SPA
RUN echo 'server { \n\
    listen 80; \n\
    server_name _; \n\
    root /usr/share/nginx/html; \n\
    index index.html; \n\
    \n\
    # Compression \n\
    gzip on; \n\
    gzip_vary on; \n\
    gzip_min_length 1024; \n\
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json; \n\
    \n\
    # Security headers \n\
    add_header X-Frame-Options "SAMEORIGIN" always; \n\
    add_header X-Content-Type-Options "nosniff" always; \n\
    add_header X-XSS-Protection "1; mode=block" always; \n\
    \n\
    # Cache static assets \n\
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ { \n\
        expires 1y; \n\
        add_header Cache-Control "public, immutable"; \n\
    } \n\
    \n\
    # Flutter routing - serve index.html for all routes \n\
    location / { \n\
        try_files $uri $uri/ /index.html; \n\
    } \n\
} \n' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
