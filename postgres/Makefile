include ../common.mk
include ../build.mk

FRAGMENTS=$(wildcard *.d/*.conf)

install::
	$(INSTALL_DIR) $(addprefix $(DESTDIR)$(unitdir_usr)/,$(sort $(dir $(FRAGMENTS))))
	for i in $(FRAGMENTS); do \
	  $(INSTALL_DATA) $$i $(DESTDIR)$(unitdir_usr)/$$i; \
	done
