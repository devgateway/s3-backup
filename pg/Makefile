INSTALL := install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644
INSTALL_DIR = $(INSTALL) -d

prefix := /usr/local
bindir = /bin
unit_dir = /etc/systemd/system

UNITS = $(wildcard *.timer *.service)
FRAGMENTS = $(wildcard *.d/*.conf)

.PHONY: install

install:
	$(INSTALL_DIR) $(DESTDIR)$(prefix)$(bindir) $(addprefix $(DESTDIR)$(unit_dir)/,$(dir $(FRAGMENTS)))
	$(INSTALL_PROGRAM) backup_pg.sh $(DESTDIR)$(prefix)$(bindir)
	$(INSTALL_DATA) $(UNITS) $(DESTDIR)$(unit_dir)
	for frag in $(FRAGMENTS); do \
	  $(INSTALL_DATA) $$frag $(DESTDIR)$(unit_dir)/$$frag; \
	done
