#!/bin/sh -e
# Back up Postgres to S3 bucket
# Usage: $0 base|wal

. functions.sh

check_vars S3_BUCKET_NAME

if [ "$1" = "base" ]; then
  echo "Doing base backup"
  : ${S3_BASE_NAME:=base-%F_%T.tar.gz}
  DATA_DIR="$(psql -Atc "SELECT setting FROM pg_settings WHERE name = 'data_directory'")"
  SIZE="$(estimate_size "$DATA_DIR")"
  pg_basebackup --wal-method=none --format=tar --pgdata=- \
    | gzip | s3_upload_stdin "$S3_BASE_NAME" "$SIZE"
else
  check_vars WAL_DIR
  : ${S3_BASE_NAME:=wal-%F_%T.tar.gz}
  echo "Doing WAL backup from $WAL_DIR"
  SIZE="$(estimate_size "$WAL_DIR")"
  TIMESTAMP="$(mktemp)"
  trap "rm -f '$TIMESTAMP'" EXIT
  tar -cC "$WAL_DIR" -b $TAR_BLOCKING_FACTOR \
      --warning=no-file-changed \
      --warning=no-file-removed . \
    | gzip | s3_upload_stdin "$S3_BASE_NAME" "$SIZE"
  find "$WAL_DIR" -type f ! -newer "$TIMESTAMP" -delete
fi
