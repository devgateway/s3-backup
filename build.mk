SCRIPTS=$(wildcard *.sh)
SERVICES=$(wildcard *.service)
TIMERS=$(wildcard *.timer)

.PHONY: install clean

%.service.dist: %.service
	sed \
	  -e '/^ExecStart/ s!\([^=[:space:]]\+\.sh\)!$(bindir)/\1!' \
	  -e '/^EnvironmentFile/ s![^=[:space:]]\+$$!$(confdir)/$(CONF_FILE)!' \
	  $< > $@

%.sh.dist: %.sh
	sed \
	  -e 's![^[:space:]]*\(functions\.sh\)$$!$(libdir)/\1!' \
	  $< > $@

install:: $(addsuffix .dist,$(SCRIPTS) $(SERVICES))
	$(INSTALL_DATA) $(TIMERS) $(DESTDIR)$(unitdir)/
	for i in $(SERVICES); do \
	  $(INSTALL_DATA) $$i.dist $(DESTDIR)$(unitdir)/$${i##*/}; \
	done
	for i in $(SCRIPTS); do \
	  $(INSTALL_PROGRAM) $$i.dist $(DESTDIR)$(bindir)/$${i##*/}; \
	done

clean::
	-rm -f *.dist
