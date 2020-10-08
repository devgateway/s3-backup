#!/bin/sh -e
: ${PG_DATA_DIR:=/var/lib/postgresql}
: ${FULL_BACKUP_PERIOD:=$((60 * 60 * 24 * 7))}

MY_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/$(basename "${0%.*}")"
LOCK_FILE="$MY_DATA_DIR/lock"
LAST_FULL="$MY_DATA_DIR/last_full"

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

do_full_backup() {
  echo "Doing full backup"
}

do_incremental_backup() {
  echo "Doing incremental backup"
}

if [ ! -d "$PG_DATA_DIR" ]; then
  exit_with_error 2 "Postgres data directory doesn't exist: $PG_DATA_DIR"
fi

if [ ! -d "$MY_DATA_DIR" ]; then
  mkdir -p "$MY_DATA_DIR"
fi

if [ -e "$LOCK_FILE" ]; then
  exit_with_error 3 "Lock file exists: $LOCK_FILE"
else
  touch "$LOCK_FILE"
fi

if [ -r "$LAST_FULL" ]; then
  LAST_FULL_BACKUP_TIME="$(stat -c %Y "$LAST_FULL")"
else
  echo "Full backup never done before"
fi

DATE_DIFF=$(($(date +%s) - ${LAST_FULL_BACKUP_TIME:-0}))
if [ "$DATE_DIFF" -lt "$FULL_BACKUP_PERIOD" ]; then
  do_incremental_backup
else
  do_full_backup
fi

rm -f "$LOCK_FILE"
