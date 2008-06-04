# Makefile for openldap-dit

NAME = openldap-dit
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
	install -m 0755 *.sh $(DESTDIR)$(ldapdatadir)/$(NAME)
	install -m 0644 *.schema $(DESTDIR)$(ldapschemadir)
	install -m 0644 README* TODO LICENSE $(DESTDIR)$(docdir)
	install -m 0644 *.ldif *.conf $(DESTDIR)$(ldapdatadir)/$(NAME)

install-mandriva:
	@make \
		ldapdatadir=$(DESTDIR)$(datadir)/openldap \
		ldapconfdir=$(DESTDIR)$(sysconfdir)/openldap \
		ldapschemadir=$(DESTDIR)$(datadir)/openldap/schema \
		install-generic

