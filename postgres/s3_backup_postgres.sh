#!/bin/sh -e
# Back up Postgres to S3 bucket
# Usage: $0 base|wal

. functions.sh

check_vars S3_BUCKET_NAME

do_base_backup() {
  pg_basebackup --wal-method=none --format=tar --pgdata=-
}

do_wal_backup() {
  tar -b $TAR_BLOCKING_FACTOR -cC "$1" --warning=no-file-changed --warning=no-file-removed .
}

s3_upload_stdin() {
  local S3_URL="s3://$S3_BUCKET_NAME/$S3_PREFIX$(date "+$S3_FILE_NAME" | s3_escape)"
  aws s3 cp - "$S3_URL" --expected-size "$1" --quiet
}

: ${S3_FILE_NAME:=%F_%T.tar.gz}

if [ "$1" = "base" ]; then
  echo "Doing base backup"
  DATA_DIR="$(psql -Atc "SELECT setting FROM pg_settings WHERE name = 'data_directory'")"
  SIZE="$(estimate_size "$DATA_DIR")"
  do_base_backup | gzip | s3_upload_stdin "$SIZE"
else
  check_vars WAL_DIR
  echo "Doing WAL backup from $WAL_DIR"
  SIZE="$(estimate_size "$WAL_DIR")"
  TIMESTAMP="$(mktemp)"
  trap "rm -f '$TIMESTAMP'" EXIT
  do_wal_backup "$WAL_DIR" | gzip | s3_upload_stdin "$SIZE"
  find "$WAL_DIR" -type f ! -newer "$TIMESTAMP" -delete
fi
