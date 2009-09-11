# Makefile for openldap-dit

NAME = openldap-dit
VERSION = 0.20
DESTDIR =
prefix = /usr
bindir = $(prefix)/bin
sbindir = $(prefix)/sbin
datadir = $(prefix)/share
sysconfdir = /etc
docdir = $(datadir)/doc/$(NAME)

ldapdatadir = $(datadir)/slapd
mydir = $(ldapdatadir)/$(NAME)
ldapscriptdir = $(ldapdatadir)

install:
	mkdir -p $(DESTDIR)$(mydir)
	mkdir -p $(DESTDIR)$(docdir)
	mkdir -p $(DESTDIR)$(ldapscriptdir)
	mkdir -p $(DESTDIR)$(mydir)/acls
	mkdir -p $(DESTDIR)$(mydir)/databases
	mkdir -p $(DESTDIR)$(mydir)/overlays
	mkdir -p $(DESTDIR)$(mydir)/schemas
	mkdir -p $(DESTDIR)$(mydir)/modules
	install -m 0755 *.sh $(DESTDIR)$(ldapscriptdir)
	install -m 0644 schemas/* $(DESTDIR)$(mydir)/schemas
	install -m 0644 doc/* TODO LICENSE COPYRIGHT $(DESTDIR)$(docdir)
	install -m 0644 acls/* $(DESTDIR)$(mydir)/acls/
	install -m 0644 databases/* $(DESTDIR)$(mydir)/databases/
	install -m 0644 overlays/* $(DESTDIR)$(mydir)/overlays/
	install -m 0644 modules/* $(DESTDIR)$(mydir)/modules/

clean:
	rm -rf *~ $(NAME)-$(VERSION) $(NAME)-$(VERSION).tar.bz2 debian/$(NAME)
	rm -f $(NAME)*$(VERSION)*deb
	rm -f $(NAME)*$(VERSION)*dsc
	rm -f $(NAME)*$(VERSION)*build
	rm -f $(NAME)*$(VERSION)*changes
	rm -f $(NAME)*$(VERSION)*tar.gz

tarball: clean
	mkdir $(NAME)-$(VERSION)
	cp -a Makefile *.sh schemas doc TODO LICENSE COPYRIGHT acls databases overlays $(NAME)-$(VERSION)
	cp -a debian $(NAME)-$(VERSION)
	tar cjf $(NAME)-$(VERSION).tar.bz2 $(NAME)-$(VERSION)
	rm -rf $(NAME)-$(VERSION)

