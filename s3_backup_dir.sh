#!/bin/sh
set -e
source functions.sh

if ! check_vars S3_BUCKET_NAME S3_PREFIX 1; then
  exit 1
fi

if [ ! -d "$1" ]; then
  echo "$1 is not a directory" >&2
  exit 2
fi

: ${BLOCKING_FACTOR:=20}

# ustar format uses 512 B blocks
BLOCK_SIZE=512
APPARENT_BLOCKS=$(du --apparent-size -sB $BLOCK_SIZE "$1" | grep -o '^[[:digit:]]\+')

# each entry has a one-block header
HEADER_BLOCKS=$(find "$1" -mindepth 1 -printf 1 | wc -c)

# two zero blocks to mark EOF
BLOCKS=$(($APPARENT_BLOCKS + $HEADER_BLOCKS + 2))

# round the blocks up to BLOCKING_FACTOR
if [ $(($BLOCKS % $BLOCKING_FACTOR)) -ne 0 ]; then
  BLOCKS=$((($BLOCKS / $BLOCKING_FACTOR + 1) * $BLOCKING_FACTOR))
fi

EXPECTED_SIZE=$(($BLOCKS * $BLOCK_SIZE))

SUFFIX=.tar
S3_SUBDIR="$(basename "$1" | s3_escape)"
S3_PATH="s3://$S3_BUCKET_NAME/$S3_PREFIX/$S3_SUBDIR/$(date +%F)$SUFFIX"

tar -b $BLOCKING_FACTOR -cC "$1" . | aws s3 cp - "$S3_PATH" --expected-size "$EXPECTED_SIZE" --quiet
