#!/bin/bash
set -e

exec > /var/log/user-data.log 2>&1

echo "Starting deployment..."

APP_DIR="/home/ubuntu/app"
BACKEND_DIR="$APP_DIR/backend"

PROJECT="${project_name}"
ENV="${environment}"
REGION="${aws_region}"

sleep 10

# Clone private repo using token
if [ ! -d "$APP_DIR" ]; then
  git clone https://${github_token}@${github_repo} $APP_DIR
else
  cd $APP_DIR
  git pull https://${github_token}@${github_repo}
fi

cd $BACKEND_DIR

echo "Fetching config from SSM..."

# =========================
# DATABASE
# =========================
DB_USERNAME=$(aws ssm get-parameter \
  --region $REGION \
  --name "/$PROJECT/$ENV/db/username" \
  --query "Parameter.Value" \
  --output text)

DB_PASSWORD=$(aws ssm get-parameter \
  --region $REGION \
  --name "/$PROJECT/$ENV/db/password" \
  --with-decryption \
  --query "Parameter.Value" \
  --output text)

echo "Creating backend .env file..."

cat <<EOF > .env
DB_NAME=${db_name}
DB_USER=$DB_USERNAME
DB_PASSWORD=$DB_PASSWORD
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
