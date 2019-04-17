#!/bin/bash
# MariaDB backup/restore helper
# Copyright 2019, Development Gateway, GPL3+

: ${TEMP_ROOT:=/var/tmp/mariadb-backup}
: ${OUTPUT_DIR:=/var/spool/backup}

find_backup() {
    local DIRS

    case "$1" in
        full)
            DIRS="$(ls -1d "$TEMP_ROOT"/[[:digit:]]*full | head -n 1)"
            ;;
        last)
            DIRS="$(ls -1dr "$TEMP_ROOT"/[[:digit:]]* | head -n 1)"
            ;;
        incr)
            DIRS="$(ls -1d "$TEMP_ROOT"/[[:digit:]]* | tail -n +2)"
            ;;
    esac

    if [ -n "$DIRS" ]; then
        echo "$DIRS"
    else
        echo "Backup '$1' not found at $TEMP_ROOT" >&2
    fi
}

run_backup() {
    local BASE_NAME TARGET_DIR OUTPUT RC

    BASE_NAME="$(date +%s)_$1"
    TARGET_DIR="$TEMP_ROOT/$BASE_NAME"
    shift

    mkdir "$TARGET_DIR"
    OUTPUT="$(mariabackup --backup --target-dir="$TARGET_DIR" $@ 2>&1)"
    RC=$?
    if [ $RC -ne 0 ]; then
        echo "$OUTPUT" >&2
        exit $RC
    fi

    tar -C "$TARGET_DIR" -cf "$OUTPUT_DIR/$BASE_NAME.tar" .
    find "$1" -type f -iregex '.*\.\([mt]rg\|cs[mv]\|par\|trn\|opt\|arz\|[af]rm\|m[ay][di]\|isl\)$' -delete
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
        if [ -n "$(find "$OUTPUT_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +$(($2 - 1)) -print -quit)" ]; then
            find "$TEMP_ROOT" -mindepth 1 -delete
            run_backup full
        else
            DIR="$(find_backup last)"
            if [ -z "$DIR" ]; then
                exit 1
            fi
            run_backup incr --incremental-basedir="$DIR"
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

$0 (backup D)|prepare|restore

POSITIONAL ARGUMENT

backup
        Run backup: full every D days, otherwise incremental. D must be greater or equal to 2.

prepare
        Apply all incremental backups to the base one (overwrites files).

restore
        Restore previously prepared backup.

ENVIRONMENT

OUTPUT_DIR[=${OUTPUT_DIR}]

        Directory where tar archives will be stored.

TEMP_ROOT[=${TEMP_ROOT}]

        Storage for backup metadata and temporary data.

EOF
        exit 1
        ;;
esac
