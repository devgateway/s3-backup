INSTALL := install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644
INSTALL_DIR = $(INSTALL) -d

prefix := /usr/local
bindir = $(prefix)/bin
confdir = $(prefix)/etc
libdir = $(prefix)/lib/s3_backup
unitdir := /etc/systemd/system
