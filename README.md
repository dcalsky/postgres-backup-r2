# Introduction

[![Build Status](https://github.com/dcalsky/postgres-backup-r2/actions/workflows/build-and-push-images.yml/badge.svg?branch=master)](https://github.com/dcalsky/postgres-backup-r2/actions/workflows/build-and-push-images.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/dcalsky/postgres-backup-r2)](https://hub.docker.com/r/dcalsky/postgres-backup-r2)

This project provides Docker images to periodically back up a PostgreSQL database to Cloudflare R2, and to restore from the backup as needed.

# Usage

## Backup

```yaml
services:
  postgres:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password

  backup:
    image: dcalsky/postgres-backup-r2:17
    environment:
      SCHEDULE: '@weekly'     # optional, options: [@yearly, @monthly, @weekly, @daily, @hourly, @every 1h30m10s]
      BACKUP_KEEP_DAYS: 7     # optional, if empty, keep forever
      PASSPHRASE:             # optional
      CLOUDFLARE_R2_REGION: auto
      CLOUDFLARE_R2_ACCESS_KEY_ID: key
      CLOUDFLARE_R2_SECRET_ACCESS_KEY: secret
      CLOUDFLARE_R2_BUCKET: my-bucket
      CLOUDFLARE_R2_ENDPOINT: https://ACCOUNT_ID.r2.cloudflarestorage.com
      R2_PREFIX: backups
      POSTGRES_HOST: postgres
      POSTGRES_DATABASE: dbname
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: password
```

- Images are tagged by the major PostgreSQL version supported: `12`, `13`, `14`, `15`, `16`, `17`.
- The `SCHEDULE` variable determines backup frequency. See go-cron schedules documentation [here](http://godoc.org/github.com/robfig/cron#hdr-Predefined_schedules). Omit to run the backup immediately and then exit.
- If `PASSPHRASE` is provided, the backup will be encrypted using GPG.
- Run `docker exec <container name> sh backup.sh` to trigger a backup ad-hoc.
- If `BACKUP_KEEP_DAYS` is set, backups older than this many days will be deleted from Cloudflare R2.
- `CLOUDFLARE_R2_ENDPOINT` should be set to your Cloudflare R2 endpoint URL (<https://ACCOUNT_ID.r2.cloudflarestorage.com>).

## Apply R2 token and keys

1. Create a new bucket and any name you want.

2. Go to initial R2 Screen, and go to Manager R2 API Tokens and create a new token.

3. Set a Token Name

4. Set `Object Read & Write` Permission.

5. (Optional) Set Specify bucket, by default it will include all buckets.
Create the token.

*Now copy the following variables:*

Access Key ID -> CLOUDFLARE_R2_ACCESS_KEY_ID

Secret Access Key -> CLOUDFLARE_R2_SECRET_ACCESS_KEY

Endpoint -> CLOUDFLARE_R2_ENDPOINT = eg. <https://abc.r2.cloudflarestorage.com>

Bucket -> CLOUDFLARE_R2_BUCKET = eg. mybucket

More details: <https://developers.cloudflare.com/r2/api/s3/tokens/>

## Restore
>
> [!CAUTION]
> DATA LOSS! All database objects will be dropped and re-created.

### ... from latest backup

```sh
docker exec <container name> sh restore.sh
```

> [!NOTE]
> If your bucket has more than a 1000 files, the latest may not be restored -- only one R2 `ls` command is used

### ... from specific backup

```sh
docker exec <container name> sh restore.sh <timestamp>
```

### ... from specific object URI

```sh
docker exec <container name> sh restore.sh s3://my-bucket/backups/mydb_20250101.dump
```

# Development

## Build the image locally

`POSTGRES_VERSION` determines Postgres version.

```sh
DOCKER_BUILDKIT=1 docker build --build-arg POSTGRES_VERSION=17 .
```

## Run a simple test environment with Docker Compose

```sh
cp template.env .env
# fill out your secrets/params in .env
docker compose up -d
```

# Acknowledgements

This project is a fork and re-structuring of [postgres-restore-s3](https://github.com/eeshugerman/postgres-backup-s3), adapted to work with Cloudflare R2.
