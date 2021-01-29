TAR_BLOCKING_FACTOR=20

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

estimate_size() {
  # ustar format uses 512 B blocks
  local BLOCK_SIZE=512
  local APPARENT_BLOCKS="$(du --apparent-size -sB $BLOCK_SIZE "$1" | grep -o '^[[:digit:]]\+')"

  # each entry has a one-block header
  local HEADER_BLOCKS="$(find "$1" -mindepth 1 -printf 1 | wc -c)"

  # two zero blocks to mark EOF
  local BLOCKS=$(($APPARENT_BLOCKS + $HEADER_BLOCKS + 2))

  # round the blocks up to TAR_BLOCKING_FACTOR
  if [ $(($BLOCKS % $TAR_BLOCKING_FACTOR)) -ne 0 ]; then
    BLOCKS="$((($BLOCKS / $TAR_BLOCKING_FACTOR + 1) * $TAR_BLOCKING_FACTOR))"
  fi

  echo "$(($BLOCKS * $BLOCK_SIZE))"
}
