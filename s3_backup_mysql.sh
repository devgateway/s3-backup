#!/bin/sh
source functions.sh

if ! check_vars S3_BUCKET_NAME S3_PREFIX 1; then
  exit 1
fi

SUFFIX=.sql.gz
DUMP_FILE="$(umask 077; mktemp --suffix=$SUFFIX)"
mysqldump "$1" | gzip > "$DUMP_FILE"

S3_SUBDIR="$(basename "$1" | s3_escape)"
S3_PATH="s3://$S3_BUCKET_NAME/$S3_PREFIX/$S3_SUBDIR/$(date +%F)$SUFFIX"
aws s3 cp "$DUMP_FILE" "$S3_PATH"
RC=$?
rm -f "$DUMP_FILE"
exit $RC
