#!/bin/bash
# MariaDB backup/restore helper
# Copyright 2019, Development Gateway, GPL3+

: ${BACKUP_ROOT:=/var/spool/backup}

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
