#!/bin/sh -e
# Back up MariaDB cluster to S3 bucket
# Usage: $0 full|incr

. ../functions.sh

check_vars S3_BUCKET_NAME 1

SCRIPT=s3_backup_mariadb
: ${TEMP_ROOT:=/var/spool/$SCRIPT}

get_last_backup_dir() {
  find "$TEMP_ROOT" -maxdepth 1 -mindepth 1 -type d ! -name lost+found -print0 \
    | xargs -r0 ls -1dt \
    | head -n 1
}

get_next_backup_dir() {
  local POS=4 INDEX
  INDEX="$(set +e; echo "$1" | grep -o '[[:digit:]]\{'$POS'\}')"
  if [ -z "$INDEX" ]; then
    INDEX=0
  else
    INDEX=$(("$(echo "$INDEX" | sed 's/^0\+//')" + 1))
    if [ ${#INDEX} -gt $POS ]; then
      echo "Index $INDEX is over $POS decimal digits" >&2
      return 1
    fi
  fi
  printf "incr-%0${POS}d" $INDEX
}

# ensure single instance running
LOCK="$(acquire_lock "$SCRIPT")"
trap "rm -f '$LOCK'" EXIT

# check if incremental backup possible
LAST_BACKUP_DIR="$(get_last_backup_dir)"
if [ "$1" != "full" -a -z "$LAST_BACKUP_DIR" ]; then
  JOB_TYPE=full
  echo "No previous backup found; forcing full backup" >&2
else
  JOB_TYPE="$1"
fi

# set paths and args
if [ "$JOB_TYPE" = "full" ]; then
  TARGET_DIR="$TEMP_ROOT/full"
else
  TARGET_DIR="$TEMP_ROOT/$(get_next_backup_dir "$LAST_BACKUP_DIR")"
  FIND_EXTRA_ARGS="! -path \"$LAST_BACKUP_DIR*\""
  MARIABACKUP_EXTRA_ARGS="--incremental-dir=\"$LAST_BACKUP_DIR\""
fi

# clean up old backups
eval find \"$TEMP_ROOT\" -mindepth 1 $FIND_EXTRA_ARGS -delete

# run backup
create_dirs "$TARGET_DIR"
eval mariabackup --backup --target-dir=\"$TARGET_DIR\" $MARIABACKUP_EXTRA_ARGS

# upload to S3
S3_BASE_NAME="$(basename "$TARGET_DIR" | s3_escape).tar.gz"
SIZE="$(estimate_size "$TARGET_DIR")"
archive_dir "$TARGET_DIR" | s3_upload_stdin "$S3_BASE_NAME" "$SIZE"

# clean up, but keep metadata
find "$TARGET_DIR" -type f \
  -iregex '.*\.\([mt]rg\|cs[mv]\|par\|trn\|opt\|arz\|[af]rm\|m[ay][di]\|isl|ibd\)$' \
  -delete
