#!/bin/sh -e
# Back up Postgres to S3 bucket
# Usage: $0 base|wal

exit_with_error() {
  local RET=$1
  shift
  echo "$@" >&2
  exit $RET
}

check_vars() {
  for VAR_NAME in $@; do
    if eval "test -z \"\$$VAR_NAME\""; then
      exit_with_error 1 "$VAR_NAME not defined. Required variables are: $@"
    fi
  done
}

s3_escape() {
  tr -c "[:alnum:]-_.*'()!\\n" _
}

estimate_size() {
  # ustar format uses 512 B blocks
  local BLOCK_SIZE=512
  local APPARENT_BLOCKS="$(du --apparent-size -sB $BLOCK_SIZE "$1" | grep -o '^[[:digit:]]\+')"

  # each entry has a one-block header
  local HEADER_BLOCKS="$(find "$1" -mindepth 1 -printf 1 | wc -c)"

  # two zero blocks to mark EOF
  local BLOCKS=$(($APPARENT_BLOCKS + $HEADER_BLOCKS + 2))

  # round the blocks up to BLOCKING_FACTOR
  if [ $(($BLOCKS % $BLOCKING_FACTOR)) -ne 0 ]; then
    BLOCKS="$((($BLOCKS / $BLOCKING_FACTOR + 1) * $BLOCKING_FACTOR))"
  fi

  echo "$(($BLOCKS * $BLOCK_SIZE))"
}

do_base_backup() {
  pg_basebackup --wal-method=none --format=tar --pgdata=-
}

do_wal_backup() {
  tar -b $BLOCKING_FACTOR -cC "$1" --warning=no-file-changed --warning=no-file-removed
}

s3_upload() {
  local S3_URL="s3://$S3_BUCKET_NAME/$S3_PREFIX$(date "+$S3_FILE_NAME" | s3_escape)"
  gzip | aws s3 cp - "$S3_URL" --expected-size "$1" --quiet
}

check_vars S3_BUCKET_NAME

: ${S3_FILE_NAME:=%F_%T.tar.gz}
: ${BLOCKING_FACTOR:=20}

if [ "$1" = "base" ]; then
  echo "Doing base backup"
  DATA_DIR="$(psql -Atc "SELECT setting FROM pg_settings WHERE name = 'data_directory'")"
  SIZE="$(estimate_size "$DATA_DIR")"
  do_base_backup | s3_upload "$SIZE"
else
  check_vars WAL_DIR
  echo "Doing WAL backup from $WAL_DIR"
  SIZE="$(estimate_size "$WAL_DIR")"
  TIMESTAMP="$(mktemp)"
  trap "rm -f '$TIMESTAMP'" EXIT
  do_wal_backup "$WAL_DIR" | s3_upload "$SIZE"
  find "$WAL_DIR" -type f ! -newer "$TIMESTAMP" -delete
fi
