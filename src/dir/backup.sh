#!/bin/sh
source ../functions.sh

if ! check_vars S3_BUCKET_NAME S3_PREFIX 1; then
  exit 1
fi

EXPECTED_SIZE="$(du -sb 1 "$1" | cut -d ' ' -f 1)"

SUFFIX=.tar
S3_SUBDIR="$(basename "$1" | s3_escape)"
S3_PATH="s3://$S3_BUCKET_NAME/$S3_PREFIX/$S3_SUBDIR/$(date +%F)$SUFFIX"
tar -cC "$1" . | aws s3 cp - "$S3_PATH" --expected-size "$EXPECTED_SIZE"
