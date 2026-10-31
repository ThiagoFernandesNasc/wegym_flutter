#!/bin/sh
set -e

# Load Docker secrets as environment variables
# (Docker Compose secrets are mounted as files in /run/secrets/)
for secret_dir in /run/secrets; do
  if [ -d "$secret_dir" ]; then
    for secret_file in "$secret_dir"/*; do
      if [ -f "$secret_file" ]; then
        name=$(basename "$secret_file" | tr '[:lower:]' '[:upper:]')
        value=$(cat "$secret_file")
        case "$name" in
          DB_PASSWORD)         export POSTGRES_PASSWORD="$value" ;;
          NEXTAUTH_SECRET)     export NEXTAUTH_SECRET="$value" ;;
          GEMINI_API_KEY)      export GEMINI_API_KEY="$value" ;;
          MP_ACCESS_TOKEN)     export MP_ACCESS_TOKEN="$value" ;;
          MP_WEBHOOK_SECRET)   export MP_WEBHOOK_SECRET="$value" ;;
          NEXT_PUBLIC_MP_PUBLIC_KEY) export NEXT_PUBLIC_MP_PUBLIC_KEY="$value" ;;
          RESEND_API_KEY)      export RESEND_API_KEY="$value" ;;
          SENTRY_DSN)          export SENTRY_DSN="$value"
                               export NEXT_PUBLIC_SENTRY_DSN="$value" ;;
          SENTRY_AUTH_TOKEN)   export SENTRY_AUTH_TOKEN="$value" ;;
          REDIS_URL)           export REDIS_URL="$value" ;;
        esac
      fi
    done
  fi
done

# Construct DATABASE_URL from POSTGRES_PASSWORD (must be set)
if [ -n "$POSTGRES_PASSWORD" ]; then
  export DATABASE_URL="postgresql://postgres:${POSTGRES_PASSWORD}@db:5432/wegym?schema=public"
fi

echo "-> Running database migrations..."
npx prisma migrate deploy --schema=./prisma/schema.prisma
echo "-> Migrations complete."

echo "-> Starting application..."
exec node server.js
