# Makefile for openldap-dit

NAME = openldap-dit
VERSION = 0.30
DESTDIR =
prefix = /usr
bindir = $(prefix)/bin
sbindir = $(prefix)/sbin
datadir = $(prefix)/share
sysconfdir = /etc
docdir = $(datadir)/doc/$(NAME)
openldap_dit_dir = $(datadir)/$(NAME)

install:
	mkdir -p $(DESTDIR)$(docdir)
	mkdir -p $(DESTDIR)$(openldap_dit_dir)
	mkdir -p $(DESTDIR)$(openldap_dit_dir)/acls
	mkdir -p $(DESTDIR)$(openldap_dit_dir)/databases
	mkdir -p $(DESTDIR)$(openldap_dit_dir)/overlays
	mkdir -p $(DESTDIR)$(openldap_dit_dir)/schemas
	mkdir -p $(DESTDIR)$(openldap_dit_dir)/modules
	mkdir -p $(DESTDIR)$(openldap_dit_dir)/contents
	install -m 0755 $(NAME)-setup.sh $(DESTDIR)$(openldap_dit_dir)
	install -m 0644 schemas/* $(DESTDIR)$(openldap_dit_dir)/schemas
	install -m 0644 doc/* TODO LICENSE COPYRIGHT $(DESTDIR)$(docdir)
	install -m 0644 acls/* $(DESTDIR)$(openldap_dit_dir)/acls
	install -m 0644 databases/* $(DESTDIR)$(openldap_dit_dir)/databases
	install -m 0644 overlays/* $(DESTDIR)$(openldap_dit_dir)/overlays
	install -m 0644 modules/* $(DESTDIR)$(openldap_dit_dir)/modules
	install -m 0644 contents/* $(DESTDIR)$(openldap_dit_dir)/contents

clean:
	rm -rf *~ $(NAME)-$(VERSION) $(NAME)-$(VERSION).tar.bz2 debian/$(NAME)
	rm -f $(NAME)*$(VERSION)*deb
	rm -f $(NAME)*$(VERSION)*dsc
	rm -f $(NAME)*$(VERSION)*build
	rm -f $(NAME)*$(VERSION)*changes
	rm -f $(NAME)*$(VERSION)*tar.gz

tarball: clean
	mkdir $(NAME)-$(VERSION)
	cp -a Makefile $(NAME)-setup.sh schemas doc TODO LICENSE COPYRIGHT acls databases overlays modules contents $(NAME)-$(VERSION)
	cp -a debian $(NAME)-$(VERSION)
	tar czf $(NAME)-$(VERSION).tar.gz $(NAME)-$(VERSION)
	rm -rf $(NAME)-$(VERSION)
