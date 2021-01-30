#!/bin/sh -e
# Back up a directory to S3 bucket
# Usage: $0 PATH
. ../functions.sh

check_vars S3_BUCKET_NAME 1

if [ ! -d "$1" ]; then
  exit_with_error 10 "$1 is not a directory"
fi

: ${S3_BASE_NAME:=$(basename "$1" | s3_escape).tar.gz}
SIZE="$(estimate_size "$1")"
archive_dir "$1" | s3_upload_stdin "$S3_BASE_NAME" "$SIZE"
