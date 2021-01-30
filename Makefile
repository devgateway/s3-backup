INSTALL := install
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644
INSTALL_DIR = $(INSTALL) -d

prefix := /usr/local
bindir = $(prefix)/bin
confdir = $(prefix)/etc
libdir = $(prefix)/lib/s3_backup
unitdir := /etc/systemd/system

SCRIPTS=$(wildcard */*.sh)
SERVICES=$(wildcard */*.service)
TIMERS=$(wildcard */*.timer)
CONF_FILE=$(wildcard *.conf)

.PHONY: all install uninstall clean

all: $(addsuffix .dist,$(SCRIPTS) $(SERVICES))

install: | all
	$(INSTALL_DIR) \
	  $(DESTDIR)$(bindir) \
	  $(DESTDIR)$(libdir) \
	  $(DESTDIR)$(confdir) \
	  $(DESTDIR)$(unitdir)
	$(INSTALL_DATA) functions.sh $(DESTDIR)$(libdir)
	$(INSTALL_DATA) $(CONF_FILE) $(DESTDIR)$(confdir)
	$(INSTALL_DATA) $(TIMERS) $(DESTDIR)$(unitdir)/
	for svc in $(SERVICES); do \
	  $(INSTALL_DATA) $$svc.dist $(DESTDIR)$(unitdir)/$${svc##*/}; \
	done
	for scr in $(SCRIPTS); do \
	  $(INSTALL_PROGRAM) $$scr.dist $(DESTDIR)$(bindir)/$${scr##*/}; \
	done

%.service.dist: %.service
	sed \
	  -e '/^ExecStart/ s!\([^=[:space:]]\+\.sh\)!$(bindir)/\1!' \
	  -e '/^EnvironmentFile/ s![^=[:space:]]\+$$!$(confdir)/$(CONF_FILE)!' \
	  $< > $@

%.sh.dist: %.sh
	sed -e 's![^[:space:]]*\(functions\.sh\)$$!$(libdir)/\1!' $< > $@

clean:
	-rm -f */*.dist
