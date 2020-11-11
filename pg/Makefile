INSTALL := install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644
INSTALL_DIR = $(INSTALL) -d

prefix := /usr/local
bindir = $(prefix)/bin
unit_dir = /etc/systemd/system

SERVICE_UNITS = $(wildcard *.service)
TIMER_UNITS = $(wildcard *.timer)
FRAGMENT_DIRS = $(wildcard *.d)
FRAGMENTS = $(wildcard *.d/*.conf)

install:
	$(INSTALL_DIR) $(bindir) $(addprefix $(prefix)$(unit_dir)/,$(FRAGMENT_DIRS))
	$(INSTALL_PROGRAM) backup_pg.sh $(DESTDIR)$(bindir)
	for frag in $(FRAGMENTS); do \
	  $(INSTALL_DATA) $$frag $(prefix)$(unit_dir)/$$frag; \
	done
