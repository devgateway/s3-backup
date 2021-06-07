#!/bin/sh -e
# Back up MariaDB cluster to S3 bucket
# Usage: $0 full|incr

. ../functions.sh

check_vars S3_BUCKET_NAME 1

SCRIPT=s3_backup_mariadb
: ${TEMP_ROOT:=/var/spool/$SCRIPT}

get_last_backup_dir() {
  find "$TEMP_ROOT" -maxdepth 1 -mindepth 1 -type d -print0 \
    | xargs -0 ls -1dt \
    | head -n 1
}

get_next_backup_dir() {
  local POS=4 INDEX WITH_ZEROES
  if [ -z "$1" ]; then
    INDEX=0
  else
    WITH_ZEROES=$(echo "$1" | grep -o '[[:digit:]]\{'$POS'\}$')
    INDEX=$((10#$WITH_ZEROES + 1))
    if [ ${#INDEX} -gt $POS ]; then
      echo "Index $INDEX is over $POS decimal digits" >&2
      return 1
    fi
  fi
  printf "%0${POS}d" $INDEX
}

LOCK="$(acquire_lock "$SCRIPT")"
trap "rm -f '$LOCK'" EXIT

LAST_BACKUP_DIR="$(get_last_backup_dir)"
if [ "$1" != "full" -a -z "$LAST_BACKUP_DIR" ]; then
  JOB_TYPE=full
  echo "No previous backup found; forcing full backup" >&2
else
  JOB_TYPE=incr
fi

if [ "$JOB_TYPE" = "full" ]; then
  TARGET_DIR="$TEMP_ROOT/full"
else
fi
create_dirs "$TEMP_ROOT"
