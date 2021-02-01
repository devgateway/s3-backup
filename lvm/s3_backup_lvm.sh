#!/bin/sh -e
# Back up a logical volume to S3 bucket
# Usage: $0 LV_PATH
. ../functions.sh

NAME="$(basename "$1" | s3_escape)"
TAG="$NAME_deleteme"
SELECT_EXPR="lv_attr=~^s && lv_tags={$TAG}"

create_snapshot() {
lvcreate \
  --snapshot "$1" \
  --extents "${LV_EXTENTS:-100%FREE}" \
  --addtag "$TAG" \
  --permission r \
  --quiet --quiet
}

find_snapshots() {
  lvs \
    --noheadings \
    --select "$SELECT_EXPR" \
    --options lv_path \
  | tr -d ' '
}

clear_snapshots() {
  for lv in $(find_snapshots); do
    umount $lv || true
  done
  lvremove \
    --force \
    --select "$SELECT_EXPR" \
    --quiet --quiet
}

check_vars S3_BUCKET_NAME 1

test -b "$1" || exit_with_error 10 "$1 is not a block device"
CACHE=/var/cache/duplicity
test -d "$CACHE" || mkdir "$CACHE"

MOUNT_POINT="$(mktemp --directory --tmpdir=/mnt)"
clear_snapshots
create_snapshot
DEV="$(find_snapshots)"
mount -o ro,noexec "$DEV" "$MOUNT_POINT"
trap "clear_snapshots; rmdir '$MOUNT_POINT'" EXIT

eval "duplicity \
  --archive-dir '$CACHE' \
  --name '$NAME' \
  --full-if-older-than '${FULL_IF_OLDER_THAN:-1M}' \
  ${DUPLICITY_OPTIONS:---no-encryption --s3-use-ia} \
  --exclude '$MOUNT_POINT/lost+found' \
  '$MOUNT_POINT' 'boto3+s3://$S3_BUCKET_NAME/$S3_PREFIX'"
