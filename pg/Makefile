INSTALL := install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644
INSTALL_DIR = $(INSTALL) -d

install:
	$(INSTALL_DIR) $(DESTDIR)$(prefix)/bin
	$(INSTALL_PROGRAM) backup_pg.sh $(DESTDIR)$(prefix)/bin
