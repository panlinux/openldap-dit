# Makefile for openldap-dit

NAME = openldap-dit
VERSION=`cat VERSION`
DESTDIR =
prefix = /usr
bindir = $(prefix)/bin
sbindir = $(prefix)/sbin
datadir = $(prefix)/share
sysconfdir = /etc
docdir = $(datadir)/doc/$(NAME)

ldapdatadir = $(datadir)/slapd
ldapconfdir = $(sysconfdir)/ldap
ldapschemadir = $(ldapconfdir)/schema
ldapscriptdir = $(ldapdatadir)

install:
	@echo "Please select among the available targets:"
	@echo "install-ubuntu: for Ubuntu and Debian"
	@echo "install-mandriva: for Mandriva"
	@echo "install-generic: supply your own makefile variables"
	@exit 0

install-generic install-ubuntu:
	mkdir -p $(DESTDIR)$(ldapschemadir)
	mkdir -p $(DESTDIR)$(ldapdatadir)/$(NAME)
	mkdir -p $(DESTDIR)$(docdir)
	mkdir -p $(DESTDIR)$(ldapscriptdir)
	install -m 0755 *.sh $(DESTDIR)$(ldapscriptdir)
	install -m 0644 *.schema $(DESTDIR)$(ldapschemadir)
	install -m 0644 README* VERSION TODO LICENSE COPYRIGHT $(DESTDIR)$(docdir)
	install -m 0644 *.ldif *.conf $(DESTDIR)$(ldapdatadir)/$(NAME)

install-mandriva:
	@make \
		ldapdatadir=$(datadir)/openldap \
		ldapconfdir=$(sysconfdir)/openldap \
		ldapschemadir=$(datadir)/openldap/schema \
		ldapscriptdir=$(datadir)/openldap/scripts \
		install-generic

clean:
	rm -rf *~ $(NAME)-$(VERSION) $(NAME)-$(VERSION).tar.bz2

tarball: clean
	mkdir $(NAME)-$(VERSION)
	cp Makefile *.spec *.sh *.conf *.schema README* VERSION TODO LICENSE COPYRIGHT *.ldif $(NAME)-$(VERSION)
	tar cjf $(NAME)-$(VERSION).tar.bz2 $(NAME)-$(VERSION)
	rm -rf $(NAME)-$(VERSION)

