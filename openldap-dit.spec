# XXX
# NEEDS UPDATING

Name: openldap-mandriva-dit
Summary: Sample DIT for OpenLDAP
Version: 0.18
Release: %mkrel 1
License: GPL
Group: System/Servers
# Source at http://svn.mandriva.com/cgi-bin/viewvc.cgi/mdv/corporate/cs4/devel/openldap-mandriva-dit/current/
Source0: mandriva-dit-base-template.ldif
Source1: mandriva-dit-access-template.conf
Source2: mandriva-dit-setup.sh
Source3: mandriva-dit-slapd-template.conf
Source4: README.mandriva.dit
Source5: LICENSE.mandriva.dit
Source6: README.dns.mandriva.dit
Source7: README.dhcp.mandriva.dit
Source8: README.sudo.mandriva.dit
Source9: README.samba.mandriva.dit
Source10: README.kde.mandriva.dit
Source11: TODO.mandriva.dit
Source12: kde.schema
Source13: kderc2ldif.sh
Source14: README.heimdal.mandriva.dit
Requires: openldap-servers >= 2.3
Requires: openldap-clients
# For when we have the schemas splitted off of openldap-servers
#Requires: openldap-extra-schemas
URL: http://qa.mandriva.com/twiki/bin/view/Main/OpenldapDit
BuildRoot: %{_tmppath}/%{name}-%{version}-root-%(id -u -n)

%description
This package contains a template LDIF file, access control rules and a simple
installation script for a suggested DIT (Directory Information Tree) to use
with an OpenLDAP server. The main characteristic of this DIT is a granular
access control via several standard administration groups. Please see the
README file for more information.

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p %{buildroot}%{_datadir}/openldap/mandriva-dit
mkdir -p %{buildroot}%{_datadir}/openldap/scripts
mkdir -p %{buildroot}%{_datadir}/openldap/schema
mkdir -p %{buildroot}%{_sysconfdir}/openldap
install -m 0644 %{_sourcedir}/mandriva-dit-base-template.ldif %{buildroot}%{_datadir}/openldap/mandriva-dit
install -m 0644 %{_sourcedir}/mandriva-dit-access-template.conf %{buildroot}%{_datadir}/openldap/mandriva-dit
install -m 0644 %{_sourcedir}/mandriva-dit-slapd-template.conf %{buildroot}%{_datadir}/openldap/mandriva-dit
install -m 0644 %{_sourcedir}/kde.schema %{buildroot}%{_datadir}/openldap/schema
install -m 0755 %{_sourcedir}/mandriva-dit-setup.sh %{buildroot}%{_datadir}/openldap/scripts
install -m 0755 %{_sourcedir}/kderc2ldif.sh %{buildroot}%{_datadir}/openldap/scripts
install -m 0644 %{_sourcedir}/LICENSE.mandriva.dit LICENSE
install -m 0644 %{_sourcedir}/README.mandriva.dit README
install -m 0644 %{_sourcedir}/README.dns.mandriva.dit README.dns
install -m 0644 %{_sourcedir}/README.samba.mandriva.dit README.samba
install -m 0644 %{_sourcedir}/README.dhcp.mandriva.dit README.dhcp
install -m 0644 %{_sourcedir}/README.sudo.mandriva.dit README.sudo
install -m 0644 %{_sourcedir}/README.kde.mandriva.dit README.kde
install -m 0644 %{_sourcedir}/README.heimdal.mandriva.dit README.heimdal
install -m 0644 %{_sourcedir}/TODO.mandriva.dit TODO

# http://qa.mandriva.com/show_bug.cgi?id=23381
sed -i "s,@LIBDIR@,%{_libdir},g" \
	%{buildroot}%{_datadir}/openldap/mandriva-dit/mandriva-dit-slapd-template.conf

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)
%doc README* LICENSE TODO
%{_datadir}/openldap/scripts/mandriva-dit-setup.sh
%{_datadir}/openldap/scripts/kderc2ldif.sh
%{_datadir}/openldap/mandriva-dit
%{_datadir}/openldap/schema/kde.schema

%changelog
* Mon Oct 15 2007 Andreas Hasenack <andreas@mandriva.com> 0.18-1mlcs4
- supply default sudo options in base ldif

* Tue Aug 28 2007 Andreas Hasenack <andreas@mandriva.com> 0.17-1mlcs4
- fix group owner acl so it doesn't terminate there: the other acls have
  to be checked as well

* Tue Aug 28 2007 Andreas Hasenack <andreas@mandriva.com> 0.16-1mlcs4
- fix regexp for account admins existing group editing acl
- also install Heimdal README

* Thu Aug 09 2007 Andreas Hasenack <andreas@mandriva.com> 0.15-1mlcs4
- allow group owner to change members of posix groups too

* Thu Jul 26 2007 Andreas Hasenack <andreas@mandriva.com> 0.14-1mlcs4
- also unlimit time/size for Account Admins group

* Tue Nov 21 2006 Andreas Hasenack <andreas@mandriva.com> 0.13-1mlcs4
- initial support for KDEConfig branch
- added configuration example for the unique overlay (#29011)

* Mon Aug 21 2006 Andreas Hasenack <andreas@mandriva.com> 0.12-1mlcs4
- added some command-line options to the setup script

* Mon Jul 31 2006 Andreas Hasenack <andreas@mandriva.com> 0.11-1mlcs4
- major simplification of ACLs: Unix, Samba and Kerberos Admins were
  merged into Account Admins
- docs updated regarding this change

* Mon Jul 24 2006 Andreas Hasenack <andreas@mandriva.com> 0.10-2mlcs4
- added substring indexing to sambaSID as allowed/required by new samba-3.0.23 schema
- added equality indexing to sambaSIDList

* Mon Jul 24 2006 Andreas Hasenack <andreas@mandriva.com> 0.10-1mlcs4
- fixed #23918 (DNS Admin write ACL)

* Thu Jun 27 2006 Andreas Hasenack <andreas@mandriva.com> 0.9-3mdk
- fixed #23381 (openldap module loading on x86_64)
- this is no more a noarch package due to this bug :(
- small documentation addendum to README.heimdal

* Thu Jun 22 2006 Andreas Hasenack <andreas@mandriva.com> 0.9-2mdk
- added TODO file
- fixed ACL to allow the user to change some of his own personal attributes
- improved Heimdal documentation setup with instructions on how to integrate
  authentication sources (samba, posix and kerberos)

* Tue Jun 20 2006 Andreas Hasenack <andreas@mandriva.com> 0.9-1mdk
- re-releasing as version 0.9, changes were too extensive

* Tue Jun 06 2006 Andreas Hasenack <andreas@mandriva.com> 0.8-2mdk
- added suggested usage for smbldap-populate to README.samba
- support for kerberos attributes and object classes (heimdal) in ACLs
- added kerberos admins group and its respective admin user
- updated documentation regarding kerberos/heimdal
- added support for referential integrity in group memberships, disabled by
  default for now

* Fri Jun 02 2006 Andreas Hasenack <andreas@mandriva.com> 0.8-1mdk
- major ACL rewrite:
  - allow samba to add its classes/attributes to existing posix entries
    that still to not have them (i.e., just pure unix users)
  - fix pwdReset access
  - fix dhcp readers acl
  - fix dns acl for base entry
  - fix shadowLastChange access logic
  - cleanup
  - let Unix Admins also create entries under Host. After all, these
    are posix entries and will show up as unix users, although they
    are mainly used by samba
  - remove one XXX, yay :)
  - move @inetOrgPerson
- updated README.dns regarding the use of hostnames (and not IP addresses) in
  named.conf

* Mon May 15 2006 Andreas Hasenack <andreas@mandriva.com> 0.7-1mdk
- fix a loophole in ACLs which permitted some system users to include
  themselves in other groups, thus gaining more privileges. We now
  have the "ou=System Groups" branch to differenciate from the
  regular group accounts

* Wed May 10 2006 Andreas Hasenack <andreas@mandriva.com> 0.6-4mdk
- allow some objectClasses in ACLs for the Address Book branch

* Tue May 09 2006 Andreas Hasenack <andreas@mandriva.com> 0.6-3mdk
- included README.samba in spec file

* Tue May 09 2006 Andreas Hasenack <andreas@mandriva.com> 0.6-2mdk
- more fixes for DHCP ACLs
- added README.sudo

* Fri May 05 2006 Andreas Hasenack <andreas@mandriva.com> 0.6-1mdk
- add admin account to the summary that is displayed before conf files are
  touched
- add README.dns, README.samba, README.dhcp
- fixed dhcp ACLs, added new group for dhcp read access (anonymous access
  is still allowed, though)
- added default indexes for dhcp attributes

* Wed May 03 2006 Andreas Hasenack <andreas@mandriva.com> 0.5-1mdk
- fixed /etc/openldap/ldap.conf creation: the changed options were being
  left commented instead of activated
- reduce calls to hostname
- fix dns acls, there was a regexp leftover in there

* Tue May 02 2006 Andreas Hasenack <andreas@mandriva.com> 0.4-1mdk
- fixed ou=DNS ACLs, tested with bind
- created new DNS group whose members can read ou=dns. This avoids
  the equivalent of the domain transfer vulnerability, where everyone could
  read the whole DNS domain database
- doc update

* Thu Apr 27 2006 Andreas Hasenack <andreas@mandriva.com> 0.3-1mdk
- load password policy schema by default, because if one tries to load
  the ppolicy overlay without this schema weird errors (hard for a beginner to
  debug) show up
- add some text to the README about the fact that we are no longer using the
  "rootdn" account of the directory
- added support for password policies

* Thu Apr 20 2006 Andreas Hasenack <andreas@mandriva.com> 0.2-2mdk
- removed uid=sudo from README file since we don't provide this account
  anymore
- require openldap-servers >= 2.3

* Wed Apr 12 2006 Andreas Hasenack <andreas@mandriva.com> 0.2-1mdk
- drop ACL that forbid uidNumber=0 in the directory, it
  is trickier than I thought and probably not worth the
  effort
- use description in all base ldif template entries
- more documentation entries
- drop sudo ACLs and generic sudo user for read access, it's
  not that much worth it since the password stays in the clear
  in /etc/ldap.conf
- oops, idmap support had dc=example,dc=com hardcoded in it instead
  of @SUFFIX@
- add support for the group owner concept: the owner can add/remove
  members from the group

* Wed Apr 12 2006 Andreas Hasenack <andreas@mandriva.com> 0.1-3mdk
- fix for sambaDomain ACL, catched by loic.vaillant@edge-it.fr
- added support for ou=Idmap
- added index for sambaGroupType

* Tue Apr 11 2006 Andreas Hasenack <andreas@mandriva.com> 0.1-2mdk
- dropped dialog requirement
- better password question
- show the admin dn

* Tue Apr 11 2006 Andreas Hasenack <andreas@mandriva.com> 0.1-1mdk
- initial release
