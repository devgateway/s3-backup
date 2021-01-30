include common.mk
CONF_FILE=$(wildcard *.conf)
export DESTDIR CONF_FILE

.PHONY: install uninstall clean

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
