#!/bin/sh -e
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

do_base_backup() {
}

do_wal_backup() {
}

if [ "$1" = "base" ]; then
  echo "Doing base backup"
  do_base_backup
else
  echo "Doing WAL backup"
  TIMESTAMP="$(mktemp)"
  trap "rm -f '$TIMESTAMP'" EXIT
  do_wal_backup
fi
