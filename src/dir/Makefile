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
BUILDDIR=build

# overridable install binaries defined
INSTALL=install
INSTALL_PROGRAM=$(INSTALL)
INSTALL_DATA=$(INSTALL) -m 644

.PHONY: all
all: $(patsubst backup%,$(BUILDDIR)/$(BASENAME)%,$(wildcard backup*))

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

$(BUILDDIR)/$(BASENAME)%: backup% | $(BUILDDIR)
	sed \
	  -e 's|backup\(\.sh\)|$(BINDIR)\1|g' \
	  -e 's|\.\.\(/functions\.sh\)|$(LIBDIR)\1|g' \
	  $< > $@

.PHONY: clean
clean:
	-rm -rf $(BUILDDIR)
