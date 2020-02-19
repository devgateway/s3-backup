check_vars() {
  for VAR_NAME in $@; do
    if [ -z "${!VAR_NAME}" ]; then
      echo "$VAR_NAME not defined" >&2
      echo "Required variables are: $@" >&2
      return 1
    fi
  done
}

s3_escape() {
  tr -c "[:alnum:]-_.*'()!" _
}
