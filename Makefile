include common.mk
TARBALL:=s3-backup.tgz
CONF_FILE=$(wildcard *.conf)
export DESTDIR CONF_FILE

.PHONY: install uninstall clean

$(TARBALL):
	DIR="$$(mktemp -d)"; \
	$(MAKE) DESTDIR="$$DIR" confdir=/etc install && \
	tar -caf "$@" -C "$$DIR" . && \
	rm -rf "$$DIR"

install:
	$(INSTALL_DIR) \
	  $(DESTDIR)$(bindir) \
	  $(DESTDIR)$(libdir) \
	  $(DESTDIR)$(confdir) \
	  $(DESTDIR)$(unitdir)
	$(INSTALL_DATA) functions.sh $(DESTDIR)$(libdir)
	$(INSTALL_DATA) $(CONF_FILE) $(DESTDIR)$(confdir)
	for dir in $(dir $(wildcard */Makefile)); do \
	  $(MAKE) -C $$dir $@; \
	done

clean:
	for dir in $(dir $(wildcard */Makefile)); do \
	  $(MAKE) -C $$dir $@; \
	done
	rm -f "$(TARBALL)"
