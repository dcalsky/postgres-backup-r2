#! /bin/sh

set -eu
set -o pipefail

source ./env.sh

echo "Creating backup of $POSTGRES_DATABASE database..."
pg_dump --format=custom \
        -h $POSTGRES_HOST \
        -p $POSTGRES_PORT \
        -U $POSTGRES_USER \
        -d $POSTGRES_DATABASE \
        $PGDUMP_EXTRA_OPTS \
        > db.dump

timestamp=$(date +"%Y-%m-%dT%H:%M:%S")
r2_uri_base="s3://${CLOUDFLARE_R2_BUCKET}/${R2_PREFIX}/${POSTGRES_DATABASE}_${timestamp}.dump"

if [ -n "$PASSPHRASE" ]; then
  echo "Encrypting backup..."
  rm -f db.dump.gpg
  gpg --symmetric --batch --passphrase "$PASSPHRASE" db.dump
  rm db.dump
  local_file="db.dump.gpg"
  r2_uri="${r2_uri_base}.gpg"
else
  local_file="db.dump"
  r2_uri="$r2_uri_base"
fi

echo "Uploading backup to $CLOUDFLARE_R2_BUCKET..."
aws $aws_args s3 cp "$local_file" "$r2_uri"
rm "$local_file"

echo "Backup complete."

if [ -n "$BACKUP_KEEP_DAYS" ]; then
  sec=$((86400*BACKUP_KEEP_DAYS))
  date_from_remove=$(date -d "@$(($(date +%s) - sec))" +%Y-%m-%d)
  backups_query="Contents[?LastModified<='${date_from_remove} 00:00:00'].{Key: Key}"

  echo "Removing old backups from $CLOUDFLARE_R2_BUCKET..."
  aws $aws_args s3api list-objects \
    --bucket "${CLOUDFLARE_R2_BUCKET}" \
    --prefix "${R2_PREFIX}" \
    --query "${backups_query}" \
    --output text \
    | xargs -n1 -t -I 'KEY' aws $aws_args s3 rm s3://"${CLOUDFLARE_R2_BUCKET}"/'KEY'
  echo "Removal complete."
fi
