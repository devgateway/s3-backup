#!/bin/sh -e
# Back up OpenLDAP DB to S3 bucket
# Usage: $0 DB_NUMBER

. ../functions.sh

check_vars S3_BUCKET_NAME 1

DUMP_FILE="$(umask 077; mktemp)"
trap "rm -f '$DUMP_FILE'" EXIT
slapcat -b "$1" | gzip > "$DUMP_FILE"

SIZE="$(stat -c %s "$DUMP_FILE")"
: ${S3_BASE_NAME:=slapd$1-%F_%T.tar.gz}
s3_upload_stdin "$S3_BASE_NAME" "$SIZE" < "$DUMP_FILE"
