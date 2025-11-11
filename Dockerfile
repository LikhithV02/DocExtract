# Multi-stage build for Flutter Web App
# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build-stage

WORKDIR /app

# Enable Flutter web support
RUN flutter config --enable-web

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

# Copy custom nginx configuration template
COPY nginx.conf /etc/nginx/templates/default.conf.template

# Expose port (Railway will provide PORT env var)
EXPOSE ${PORT:-80}

# The nginx docker image automatically processes templates in /etc/nginx/templates/
# and substitutes environment variables before starting nginx
CMD ["nginx", "-g", "daemon off;"]
