#! /bin/sh

set -u # `-e` omitted intentionally, but i can't remember why exactly :'(
set -o pipefail

source ./env.sh

r2_uri_base="s3://${CLOUDFLARE_R2_BUCKET}/${R2_PREFIX}"

if [ -z "$PASSPHRASE" ]; then
  file_type=".dump"
else
  file_type=".dump.gpg"
fi

if [ $# -eq 1 ]; then
  # Check if the argument is a full URI (starts with s3://)
  if [[ "$1" == s3://* ]]; then
    echo "Using provided object URI..."
    full_uri="$1"
  else
    # Treat as timestamp (backward compatibility)
    timestamp="$1"
    key_suffix="${POSTGRES_DATABASE}_${timestamp}${file_type}"
    full_uri="${r2_uri_base}/${key_suffix}"
  fi
else
  echo "Finding latest backup..."
  key_suffix=$(
    aws $aws_args s3 ls "${r2_uri_base}/${POSTGRES_DATABASE}" \
      | sort \
      | tail -n 1 \
      | awk '{ print $4 }'
  )
  full_uri="${r2_uri_base}/${key_suffix}"
fi

echo "Fetching backup ${full_uri} from Cloudflare R2..."
aws $aws_args s3 cp "${full_uri}" "db${file_type}"

if [ -n "$PASSPHRASE" ]; then
  echo "Decrypting backup..."
  gpg --decrypt --batch --passphrase "$PASSPHRASE" db.dump.gpg > db.dump
  rm db.dump.gpg
fi

conn_opts="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DATABASE"

echo "Restoring from backup..."
pg_restore $conn_opts --clean --if-exists db.dump
rm db.dump

echo "Restore complete."
