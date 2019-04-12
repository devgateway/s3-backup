#!/bin/bash
# MariaDB backup/restore helper
# Copyright 2019, Development Gateway, GPL3+

: ${BACKUP_ROOT:=/var/tmp/mariadb-backup}
: ${OUTPUT_DIR:=/var/spool/backup}

find_backup() {
    local CMD DIRS

    case "$1" in
        full)
            CMD='ls -1d "$BACKUP_ROOT"/* | head -n 1'
            ;;
        last)
            CMD='ls -1dr "$BACKUP_ROOT"/* | head -n 1'
            ;;
        inc)
            CMD='ls -1d "$BACKUP_ROOT"/* | tail -n +2'
            ;;
    esac

    DIRS="$(eval $CMD)"
    if [ -z "$DIRS" ]; then
        echo "Backup '$1' not found at $BACKUP_ROOT" >&2
        exit 1
    fi
    echo "$DIRS"
}

run_backup() {
    local BASE_NAME, TARGET_DIR, OUTPUT, RC

    BASE_NAME="$(date +%s)_$1"
    TARGET_DIR="$BACKUP_ROOT/$BASE_NAME"
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

run_backup_full() {
    find "$BACKUP_ROOT" -mindepth 1 -delete
    run_backup full
}

run_backup_inc() {
    local LAST_DIR="$(find_backup last)"

    run_backup inc --incremental-basedir="$LAST_DIR"
}

run_prepare() {
    local FULL_DIR="$(find_backup full)"

    mariabackup \
        --prepare \
        --apply-log-only \
        --target-dir="$FULL_DIR"

    for INC_DIR in $(find_backup inc); do
        mariabackup \
            --prepare \
            --apply-log-only \
            --target-dir="$FULL_DIR" \
            --incremental-dir="$INC_DIR"
    done
}

run_restore() {
    local FULL_DIR="$(find_backup full)"

    mariabackup \
        --copy-back \
        --target-dir="$FULL_DIR"
}

show_usage() {
    cat >&2 <<EOF
$0 - MariaDB backup/restore helper script

SYNOPSIS

$0 full|inc|prepare|restore

POSITIONAL ARGUMENT

full
        Full backup.

inc
        Incremental backup (prior full or incremental backup required).

prepare
        Apply all incremental backups to the base one (overwrites files).

restore
        Restore previously prepared backup.

ENVIRONMENT

BACKUP_ROOT[=${BACKUP_ROOT}]

        Base for all backup subdirectories.

EOF
    exit 1
}
case "$1" in
    full)
        run_backup_full
        ;;
    inc)
        run_backup_inc
        ;;
    prepare)
        run_prepare
        ;;
    restore)
        run_restore
        ;;
    *)
        show_usage
        ;;
esac
