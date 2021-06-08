# s3\_backup - Back Up to Amazon S3

This is a collection of shell scripts for backing up various services to Amazon S3. The scripts themselves are written
for `sh`, not necessarily `bash`. Some of them depend on [AWS CLI](https://aws.amazon.com/cli/), some on
[Duplicity](https://nongnu.org/duplicity/), etc. See README for each script for specific requirements. The scripts come
with Systemd units, but can be adapted to other startup systems, as long as proper environment variables are exported.

## Installation

    make confdir=/etc install clean

You can set `DESTDIR` variable to change installation root, e.g. for packaging. Although `confdir` defaults to
`/usr/local/etc`, Systemd unit files are still installed to `/etc`.

## Configuration

The file [`s3_backup.conf`](./s3_backup.conf) sets the environment shared between all scripts. It defines the path to
AWS configuration file used by Boto3 (and therefore by AWS CLI and Duplicity).

    umask 0037
    test -e /etc/aws.ini || cat >/etc/aws.ini <<EOF
    [default]
    aws_access_key_id = AKIAXXXXXXXXXXXXXXXX
    aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    region = us-east-1
    EOF
    chgrp backup /etc/aws.ini

If a backup script runs as a different user, remember to add them to a group that can read the INI file:

    usermod -aG backup postgres
    systemctl restart postgresql

You might want to have consistent settings between the backup scripts and AWS CLI in your interactive shell. In that
case, use a symlink like so:

    mkdir -p ~/.aws
    test -f /etc/aws.ini && ln -s /etc/aws.ini ~/.aws/config

## Extension

Copy the structure of a module, e.g. `slapd`, and make adjustments. You can redeclare the target `install::` (note the
[double colon](https://www.gnu.org/software/make/manual/make.html#Double_002dColon)) before or after including
`build.mk`, see [`postgres/Makefile`](postgres/Makefile) for reference.

## See Also

* [LVM](./lvm/README.md)

## Copyright

2019-2021, Development Gateway, GPLv3+, see COPYING.
