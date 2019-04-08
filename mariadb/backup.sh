#!/bin/bash
# MariaDB backup/restore helper
# Copyright 2019, Development Gateway, GPL3+

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
