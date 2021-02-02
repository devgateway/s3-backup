# `s3_backup_lvm.sh` - Back Up a File System with an LVM Snapshot

This script takes a snapshot of a given LV, mounts it, runs Duplicity backup, and removes the snapshot. It is
particularly useful for services like MongoDB, but make sure the snapshot is consistent, i.e. journaling is on.

## Requirements

1. Duplicity
2. LVM

### Installing Duplicity

Duplicity is not in Debian 10 repos, so a quick way to install is:

    wget https://launchpad.net/duplicity/0.8-series/0.8.17/+download/duplicity-0.8.17.tar.gz
    tar -xf duplicity-0.8.17.tar.gz
    cd duplicity-0.8.17/
    DEV_PKG="gettext gcc python3-dev librsync-dev"
    apt install librsync1 python3-{setuptools,boto3,future,fasteners} \
    && apt install $DEV_PKG && python3 setup.py install --prefix=/usr/local \
    && apt remove $DEV_PKG && apt autoremove

## Usage

Assuming MongoDB data is on the volume `/dev/myapp/mongo`:

    FRAG_DIR=/etc/systemd/system/s3_backup_lvm@dev-myapp-mongo.service.d
    mkdir $FRAG_DIR
    cat >$FRAG_DIR/prefix.conf <EOF
    [Service]
    Environment=S3_PREFIX=mongo/
    EOF
    systemctl daemon-reload
    systemctl enable --now s3_backup_lvm@dev-myapp-mongo.timer

## Recovery

    duplicity restore \
      --archive-dir /var/cache/duplicity \
      --name mongo \
      --no-encryption \
      --progress \
      boto3+$S3_URL /var/lib/mongodb

## Environment

### `DUPLICITY_CACHE`

Default: `/var/cache/duplicity`

Path to Duplicity cache directory.

### `DUPLICITY_OPTIONS`

Default: `--no-encryption --s3-use-ia`

Additional arguments passed to Duplicity.

### `FULL_IF_OLDER_THAN`

Default: `1M`

Interval of full backups, see *duplicity(8)*.

### `JOB_NAME`

Default: name of the logical volume (escaped for S3)

Used to uniquely tag the snapshot (*NAME*`_deleteme`), and as a `--name` subdirectory for Duplicity cache, see
*duplicity(8)*.

### `LV_EXTENTS`

Default: `100%FREE`

Create a snapshot of this size. If it's greater than the origin volume, LVM will automatically limit it. Be sure to make
the snapshot big enough to accomodate for CoW changes.
