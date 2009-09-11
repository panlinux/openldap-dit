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
ldapconfdir = $(sysconfdir)/ldap
ldapschemadir = $(ldapdatadir)/$(NAME)
ldapscriptdir = $(ldapdatadir)

install:
	mkdir -p $(DESTDIR)$(ldapschemadir)
	mkdir -p $(DESTDIR)$(ldapdatadir)/$(NAME)
	mkdir -p $(DESTDIR)$(docdir)
	mkdir -p $(DESTDIR)$(ldapscriptdir)
	install -m 0755 *.sh $(DESTDIR)$(ldapscriptdir)
	install -m 0644 schemas/*.ldif $(DESTDIR)$(ldapschemadir)
	install -m 0644 doc/* TODO LICENSE COPYRIGHT $(DESTDIR)$(docdir)

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

