INSTALL := install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644
INSTALL_DIR = $(INSTALL) -d

prefix := /usr/local
bindir = $(DESTDIR)$(prefix)/bin
unit_dir = $(DESTDIR)/etc/systemd/system

install:
	$(INSTALL_DIR) $(bindir)
	$(INSTALL_PROGRAM) backup_pg.sh $(bindir)
