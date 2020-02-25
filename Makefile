SUITE=s3_backup
PREFIX=/usr/local

# function library goes here
LIBDIR=$(PREFIX)/lib/$(SUITE)

# base name without suffix for script and units
BASENAME=$(SUITE)_$(notdir $(abspath .))

# backup script goes here
BINDIR=$(LIBDIR)

# Systemd timer and service go here, at /etc or /usr/lib
UNITDIR=/etc/systemd/system

# temporary dir for scripts with absolute paths in them
BUILDDIR=dist

# overridable install binaries defined
INSTALL=install
INSTALL_PROGRAM=$(INSTALL)
INSTALL_DATA=$(INSTALL) -m 644

# scripts and units
SCRIPTS=$(filter-out functions.sh,$(wildcard *.sh))
SERVICES=$(wildcard *.service)
TIMERS=$(wildcard *.timer)

.PHONY: all
all: $(addprefix $(BUILDDIR)/,$(SCRIPTS) $(SERVICES))

.PHONY: install
install: | all
	$(INSTALL) -d $(DESTDIR)$(BINDIR)
	$(INSTALL) -d $(DESTDIR)$(UNITDIR)
	$(INSTALL_PROGRAM) $(BUILDDIR)/$(BASENAME).sh $(DESTDIR)$(BINDIR)/
	$(INSTALL_DATA) ../functions.sh $(DESTDIR)$(LIBDIR)/
	$(INSTALL_DATA) $(BUILDDIR)/$(BASENAME)*.service $(DESTDIR)$(UNITDIR)/
	$(INSTALL_DATA) $(BUILDDIR)/$(BASENAME)*.timer $(DESTDIR)$(UNITDIR)/

$(BUILDDIR):
	-mkdir $(BUILDDIR)

$(BUILDDIR)/%.sh: %.sh | $(BUILDDIR)
	sed \
	  -e 's|[^[:space:]]\+\(functions\.sh\)$$|$(LIBDIR)/\1|g' \
	  $< > $@

$(BUILDDIR)/%.service: %.service | $(BUILDDIR)
	sed \
	  -e 's|\([^=[:space:]]\+\.sh\)|$(BINDIR)/\1|g' \
	  $< > $@

.PHONY: clean
clean:
	-rm -rf $(BUILDDIR)
