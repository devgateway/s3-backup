INSTALL := install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644
INSTALL_DIR = $(INSTALL) -d

prefix := /usr/local
bindir = /bin
unit_dir = /etc/systemd/system

UNITS = $(wildcard *.timer *.service)
FRAGMENTS = $(wildcard *.d/*.conf)
FRAGMENT_DIRS = $(addprefix $(unit_dir)/,$(sort $(dir $(FRAGMENTS))))

.PHONY: install uninstall

install:
	$(INSTALL_DIR) $(addprefix $(DESTDIR),$(prefix)$(bindir) $(FRAGMENT_DIRS))
	$(INSTALL_PROGRAM) backup_pg.sh $(DESTDIR)$(prefix)$(bindir)
	$(INSTALL_DATA) $(UNITS) $(DESTDIR)$(unit_dir)
	for frag in $(FRAGMENTS); do \
	  $(INSTALL_DATA) $$frag $(DESTDIR)$(unit_dir)/$$frag; \
	done

uninstall:
	rm -f  $(addprefix $(DESTDIR),$(prefix)$(bindir)/backup_pg.sh $(addprefix $(unit_dir)/,$(UNITS)))
	rm -rf $(addprefix $(DESTDIR),$(FRAGMENT_DIRS))
