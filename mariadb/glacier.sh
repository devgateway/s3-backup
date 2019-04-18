#!/bin/bash
# Glacier uploader
# Copyright 2019, Development Gateway, GPL3+

: ${GLACIER_DIR:=/var/spool/backup}
if [ -z "$VAULT" ]; then
  echo VAULT variable must be defined >&2
  exit 1
fi

TAR_FILE="$(OUTPUT_DIR="$GLACIER_DIR" maria-backup.sh backup)"
if [ ! -f "$TAR_FILE" ]; then
  echo "$TAR_FILE" is not a regular file >&2
  exit 1
fi

glacier-cmd upload "$VAULT" "$TAR_FILE" >/dev/null 2>&1
RC=$?

if [ $RC -eq 0 ]; then
  echo "$TAR_FILE" successfully uploaded >&2
  rm -f "$TAR_FILE"
else
  echo "Initial upload failed" >&2
  for i in $(seq 1 5); do
    echo "Resuming upload, attempt $i" >&2
    UPLOAD_ID="$(glacier-cmd listmultiparts "$VAULT" \
      | tail -n +4 \
      | head -n -1 \
      | sort -k 6 \
      | tail -n1 \
      | awk '{print $2}' )"
    if glacier-cmd upload --resume --uploadid "$UPLOAD_ID" "$VAULT" "$TAR_FILE"; then
      echo "Upload succeeded." >&2
      break
    fi
  done
  if [[ $? -ne 0 ]]; then
    echo "Upload failed after $i attempts." >&2
    exit $?
  fi
fi
