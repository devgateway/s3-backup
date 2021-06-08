# `s3_backup_mariadb.sh` - Back Up MariaDB Cluster Incrementally

The script leverages [Mariabackup](https://mariadb.com/kb/en/incremental-backup-and-restore-with-mariabackup/) for
incremental backup of a MariaDB cluster.

The backup is targeted to a certain subdirectory of a temporary directory, which is `/var/spool/s3_backup_mariadb` by
default. The target subdirectory is either `full` or `incr-NNNN`, where `NNNN` is an integer index with leading zeroes.

Before the backup, the temporary directory will be cleared of old subdirs that are not needed for current backup.

After the backup and upload of the compressed tarball, the current subdir will be pruned from *data*, leaving only
*metadata* required for the subsequent backups. The list of file extensions that are considered *data* is taken from
mariabackup source code.

## Requirements

Mariabackup needs to authenticate to the server. In most cases, just adding this snippet to `~/.my.cnf` is sufficient:

    [mariabackup]
    user=root

## Usage

Enable the timers to run full backup on the first Saturday of every month, and incremental backup daily.

    systemctl enable --now s3_backup_mariadb@{full,incr}.timer

## Recovery

To be added.

## Environment

### `TEMP_ROOT`

Default: `/var/spool/s3_backup_mariadb`

Root directory for individual backup subdirs.
