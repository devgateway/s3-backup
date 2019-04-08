#!/bin/bash
# MariaDB backup/restore helper
# Copyright 2019, Development Gateway, GPL3+

: ${BACKUP_ROOT:=/var/spool/backup}

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

create_backup_dir() {
    local DIR="$BACKUP_ROOT/$(date +%Y-%m-%d_%T)_$1"

    mkdir "$DIR"
    echo "$DIR"
}

run_backup_full() {
    local FULL_DIR

    find "$BACKUP_ROOT" -mindepth 1 -delete
    FULL_DIR="$(create_backup_dir full)"
    mariabackup \
        --backup \
        --target-dir="$FULL_DIR"
}

run_backup_inc() {
    local LAST_DIR="$(find_backup last)"
    local INC_DIR="$(create_backup_dir inc)"

    mariabackup \
        --backup \
        --target-dir="$INC_DIR" \
        --incremental-basedir="$LAST_DIR"
}

case "$1" in
    full)
        run_backup_full
        ;;
    inc)
        run_backup_inc
        ;;
    restore)
        run_restore
        ;;
    *)
        show_usage
        ;;
esac
