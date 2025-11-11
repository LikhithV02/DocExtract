#!/bin/sh
set -e

# Set PORT to Railway's value or default to 80
export PORT=${PORT:-80}

echo "Starting nginx on port $PORT"

# Substitute environment variables in nginx template
envsubst '${PORT}' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf

# Verify the config
echo "Generated nginx config:"
cat /etc/nginx/conf.d/default.conf

# Start nginx
exec nginx -g 'daemon off;'
