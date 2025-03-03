if [ -z "$CLOUDFLARE_R2_BUCKET" ]; then
  echo "You need to set the CLOUDFLARE_R2_BUCKET environment variable."
  exit 1
fi

if [ -z "$POSTGRES_DATABASE" ]; then
  echo "You need to set the POSTGRES_DATABASE environment variable."
  exit 1
fi

if [ -z "$POSTGRES_HOST" ]; then
  # https://docs.docker.com/network/links/#environment-variables
  if [ -n "$POSTGRES_PORT_5432_TCP_ADDR" ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ -z "$POSTGRES_USER" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable."
  exit 1
fi

if [ -z "$CLOUDFLARE_R2_ENDPOINT" ]; then
  echo "You need to set the CLOUDFLARE_R2_ENDPOINT environment variable."
  exit 1
fi

aws_args="--endpoint-url $CLOUDFLARE_R2_ENDPOINT"

if [ -n "$CLOUDFLARE_R2_ACCESS_KEY_ID" ]; then
  export AWS_ACCESS_KEY_ID=$CLOUDFLARE_R2_ACCESS_KEY_ID
fi
if [ -n "$CLOUDFLARE_R2_SECRET_ACCESS_KEY" ]; then
  export AWS_SECRET_ACCESS_KEY=$CLOUDFLARE_R2_SECRET_ACCESS_KEY
fi
export AWS_DEFAULT_REGION=${CLOUDFLARE_R2_REGION:-auto}
export PGPASSWORD=$POSTGRES_PASSWORD
