# Multi-stage build for React Vite frontend
# This Dockerfile is designed to run from the repository root (monorepo)

# Build stage
FROM node:18-alpine AS builder

# Accept build arguments for environment variables
ARG VITE_API_BASE_URL
ARG VITE_WS_URL

# Set them as environment variables for the build
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
ENV VITE_WS_URL=$VITE_WS_URL

WORKDIR /app

# Copy package files from frontend directory
COPY frontend/package*.json ./

# Install dependencies
RUN npm ci --legacy-peer-deps

# Copy frontend source files
COPY frontend/ ./

# Build the application with environment variables
RUN npm run build

# Production stage
FROM nginx:alpine AS runner

# Copy built assets from builder
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy nginx configuration from builder
COPY --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
