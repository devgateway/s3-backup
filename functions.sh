# desc:   Print to stderr, exit with RC
# stdin:  none
# stdout: none
# env:    none
# args:   RC message [message...]
exit_with_error() {
  local RET=$1
  shift
  echo "$@" >&2
  exit $RET
}

# desc:   Check that all vars are defined, or exit with error
# stdin:  none
# stdout: none
# env:    none
# args:   [var_name...]
check_vars() {
  for VAR_NAME in $@; do
    if eval "test -z \"\$$VAR_NAME\""; then
      exit_with_error 1 "$VAR_NAME not defined. Required variables are: $@"
    fi
  done
}

# desc:   Replace invalid chars in S3 filename
# stdin:  base_name
# stdout: safe_base_name
# env:    none
# args:   none
s3_escape() {
  tr -c "[:alnum:]-_.*'()!\\n" _
}

# desc:   Estimate size of TAR archive
# stdin:  none
# stdout: size_bytes
# env:    none
# args:   path
estimate_size() {
  # ustar format uses 512 B blocks
  local BLOCK_SIZE=512
  local APPARENT_BLOCKS="$(du --apparent-size -sB $BLOCK_SIZE "$1" | grep -o '^[[:digit:]]\+')"

  # each entry has a one-block header
  local HEADER_BLOCKS="$(find "$1" -mindepth 1 -printf 1 | wc -c)"

  # two zero blocks to mark EOF
  local BLOCKS=$(($APPARENT_BLOCKS + $HEADER_BLOCKS + 2))

  # round the blocks up to TAR_BLOCKING_FACTOR
  local TBF=${TAR_BLOCKING_FACTOR:-20}
  if [ $(($BLOCKS % $TBF)) -ne 0 ]; then
    BLOCKS="$((($BLOCKS / $TBF + 1) * $TBF))"
  fi

  echo "$(($BLOCKS * $BLOCK_SIZE))"
}

# desc:   Upload a stream to S3 file
# stdin:  data
# stdout: none
# env:    S3_BUCKET_NAME [S3_PREFIX=""]
# args:   base_name_in_date_format expected_size_bytes
s3_upload_stdin() {
  aws s3 cp - "s3://$S3_BUCKET_NAME/$S3_PREFIX$(date "+$1" | s3_escape)" \
    --expected-size "$2" \
    --quiet
}

# desc:   Archive directory in gzipped tar format
# stdin:  none
# stdout: data
# env:    [TAR_BLOCKING_FACTOR=20]
# args:   path [--tar_extra_arg...]
archive_dir() {
  local DIR="$1"
  shift
  tar -cC "$DIR" -b ${TAR_BLOCKING_FACTOR:-20} $@ . | gzip
}

export AWS_CONFIG_FILE
