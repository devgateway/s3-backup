#!/bin/bash -e
# MariaDB backup/restore helper
# Copyright 2019, Development Gateway, GPL3+

: ${BACKUP_CYCLE:=14}
: ${TEMP_ROOT:=/var/tmp/mariadb-backup}
: ${OUTPUT_DIR:=/var/spool/backup}

find_backup() {
    local DIRS

    case "$1" in
        full)
            DIRS="$(find "$TEMP_ROOT" -mindepth 1 -maxdepth 1 -type d -regex '.*/[0-9]+_full$' \
                | sort -r \
                | head -n 1)"
            ;;
        last)
            DIRS="$(find "$TEMP_ROOT" -mindepth 1 -maxdepth 1 -type d -regex '.*/[0-9]+_\(full\|incr\)$' \
                | sort -r \
                | head -n 1)"
            ;;
        incr)
            DIRS="$(find "$TEMP_ROOT" -mindepth 1 -maxdepth 1 -type d -regex '.*/[0-9]+_incr$' \
                | sort)"
            ;;
    esac

    if [ -n "$DIRS" ]; then
        echo "$DIRS"
    else
        echo "Backup '$1' not found at $TEMP_ROOT" >&2
    fi
}

run_backup() {
    local BASE_NAME TARGET_DIR OUTPUT RC TAR_FILE

    BASE_NAME="$(date +%s)_$1"
    TARGET_DIR="$TEMP_ROOT/$BASE_NAME"
    shift

    mkdir "$TARGET_DIR"
    set +e
    OUTPUT="$(mariabackup --backup --target-dir="$TARGET_DIR" $@ 2>&1)"
    RC=$?
    set -e
    if [ $RC -ne 0 ]; then
        echo "$OUTPUT" >&2
        return $RC
    fi

    TAR_FILE="$OUTPUT_DIR/$BASE_NAME.tar"
    tar -C "$TARGET_DIR" -cf "$TAR_FILE" .
    find "$TARGET_DIR" -type f -iregex '.*\.\([mt]rg\|cs[mv]\|par\|trn\|opt\|arz\|[af]rm\|m[ay][di]\|isl\)$' -delete

    echo "$TAR_FILE"
}

run_prepare() {
    local FULL_DIR="$(find_backup full)"
    if [ -z "$FULL_DIR" ]; then
        exit 1
    fi

    mariabackup \
        --prepare \
        --apply-log-only \
        --target-dir="$FULL_DIR"

    for INC_DIR in $(find_backup incr); do
        mariabackup \
            --prepare \
            --apply-log-only \
            --target-dir="$FULL_DIR" \
            --incremental-dir="$INC_DIR"
    done
}

case "$1" in
    backup)
        OLD_FULL="$(find "$TEMP_ROOT" -mindepth 1 -maxdepth 1 -type d -regex '.*/[0-9]+_full$' \
            -mtime +$(($BACKUP_CYCLE - 1)) -print -quit)"
        if [ -n "$OLD_FULL" ]; then
            echo "Found old full backups: $(echo "$OLD_FULL" | xargs), cleaning up and running full" >&2
            find "$TEMP_ROOT" -mindepth 1 -maxdepth 1 -type d -regex '.*/[0-9]+_\(full\|incr\)$' \
                -execdir rm -rf '{}' ';'
            run_backup full
        else
            DIR="$(find_backup last)"
            if [ -n "$DIR" ]; then
                echo Doing incr backup based on "$DIR" >&2
                run_backup incr --incremental-basedir="$DIR"
            else
                echo Last backup not found, doing full >&2
                run_backup full
            fi
        fi
        ;;
    prepare)
        run_prepare
        ;;
    restore)
        DIR="$(find_backup full)"
        if [ -z "$DIR" ]; then
            exit 1
        fi
        mariabackup --copy-back --target-dir="$DIR"
        ;;
    *)
        cat >&2 <<EOF
$0 - MariaDB backup/restore helper script

SYNOPSIS

$0 backup|prepare|restore

POSITIONAL ARGUMENT

backup
        Run backup: full every BACKUP_CYCLE days, otherwise incremental.

prepare
        Apply all incremental backups to the base one (overwrites files).

restore
        Restore previously prepared backup.

ENVIRONMENT

BACKUP_CYCLE[=${BACKUP_CYCLE}]

        Make full backup once in this many days; must be greater or equal to 2.

OUTPUT_DIR[=${OUTPUT_DIR}]

        Directory where tar archives will be stored.

TEMP_ROOT[=${TEMP_ROOT}]

        Storage for backup metadata and temporary data.

EOF
        exit 1
        ;;
esac
