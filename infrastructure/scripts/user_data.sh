#!/bin/bash
set -e

exec > /var/log/user-data.log 2>&1

echo "Starting deployment..."

APP_DIR="/home/ubuntu/app"
BACKEND_DIR="$APP_DIR/backend"

sleep 10

# Clone private repo using token
if [ ! -d "$APP_DIR" ]; then
  git clone https://${github_token}@${github_repo} $APP_DIR
else
  cd $APP_DIR
  git pull https://${github_token}@${github_repo}
fi

cd $BACKEND_DIR

echo "Creating backend .env file..."

cat <<EOF > .env
DB_NAME=${db_name}
DB_USER=${db_username}
DB_PASSWORD=${db_password}
DB_HOST=${db_host}
DB_PORT=5432
DJANGO_SECRET_KEY=${django_secret_key}
ALLOWED_HOSTS=${allowed_hosts}
EOF

echo ".env created."

# Start Docker
docker compose down || true
docker compose up -d --build

docker image prune -f

echo "Deployment completed successfully."
