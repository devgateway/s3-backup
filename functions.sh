TAR_BLOCKING_FACTOR=20

# desc:         Print to stderr, exit with RC
# stdin:        none
# stdout:       none
# expect vars:  none
# args:         RC message [message...]
exit_with_error() {
  local RET=$1
  shift
  echo "$@" >&2
  exit $RET
}

# desc:         Check that all vars are defined, or exit with error
# stdin:        none
# stdout:       none
# expect vars:  none
# args:         [var_name...]
check_vars() {
  for VAR_NAME in $@; do
    if eval "test -z \"\$$VAR_NAME\""; then
      exit_with_error 1 "$VAR_NAME not defined. Required variables are: $@"
    fi
  done
}

# desc:         Replace invalid chars in S3 filename
# stdin:        file path
# stdout:       safe file path
# expect vars:  none
# args:         none
s3_escape() {
  tr -c "[:alnum:]-_.*'()!\\n" _
}

# desc:         Estimate size of TAR archive
# stdin:        none
# stdout:       none
# expect vars:  none
# args:         path
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

# desc:         Upload a stream to S3 file
# stdin:        data
# stdout:       none
# expect vars:  S3_BUCKET_NAME [S3_PREFIX]
# args:         base_name_in_date_format expected_size_bytes
s3_upload_stdin() {
  aws s3 cp - "s3://$S3_BUCKET_NAME/$S3_PREFIX$(date "+$1" | s3_escape)" \
    --expected-size "$2" \
    --quiet
}
