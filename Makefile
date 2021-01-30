include common.mk
CONF_FILE=$(wildcard *.conf)

.PHONY: install uninstall clean

install:
	$(INSTALL_DIR) \
	  $(DESTDIR)$(bindir) \
	  $(DESTDIR)$(libdir) \
	  $(DESTDIR)$(confdir) \
	  $(DESTDIR)$(unitdir)
	$(INSTALL_DATA) functions.sh $(DESTDIR)$(libdir)
	$(INSTALL_DATA) $(CONF_FILE) $(DESTDIR)$(confdir)
	export DESTDIR
	for dir in $(dir $(wildcard */Makefile)); do \
	  $(MAKE) -C $$dir $@; \
	done

clean:
	for dir in $(dir $(wildcard */Makefile)); do \
	  $(MAKE) -C $$dir $@; \
	done
