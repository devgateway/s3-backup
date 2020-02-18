#!/bin/sh
if [ -z "$S3_BUCKET_NAME" ]; then
  ERR="S3_BUCKET_NAME must be defined"
elif [ ! -d "$1" ]; then
  ERR="'$1' is not a directory"
else
  ERR=
fi

if [ -n "$ERR" ]; then
  echo "$ERR" >&2
  echo >&2 <<EOF
Usage:
  $(basename "$0") DIRECTORY

Environment:
  S3_BUCKET_NAME (required) - bucket to upload to.
EOF
  exit 1
fi

EXPECTED_SIZE="$(du -sb 1 "$1" | cut -d ' ' -f 1)"
if [ ! "$EXPECTED_SIZE" -gt 0 ]; then
  echo "Can't estimate directory size, got: $EXPECTED_SIZE" >&2
  exit 1
fi

FILE_NAME="$(basename "$1" | tr -c '[:alnum:]' _)-$(date +%F).tar"
S3_PATH="s3://$S3_BUCKET_NAME/wp/$FILE_NAME"
tar -cC "$1" . | aws s3 cp - "$S3_PATH" --expected-size "$EXPECTED_SIZE"
