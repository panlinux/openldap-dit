#!/bin/bash

if [ "`id -u`" != "0" ]; then
	echo "Error, must be root user"
	exit 1
fi

SLAPTEST="/usr/sbin/slaptest"
SLAPADD="/usr/sbin/slapadd"
SLAPPASSWD="/usr/sbin/slappasswd"
slapd_conf_template="/usr/share/openldap/mandriva-dit/mandriva-dit-slapd-template.conf"
base_ldif_template="/usr/share/openldap/mandriva-dit/mandriva-dit-base-template.ldif"
acl_template="/usr/share/openldap/mandriva-dit/mandriva-dit-access-template.conf"
acl_file="/etc/openldap/mandriva-dit-access.conf"
now=`date +%s`
myfqdn=`hostname -f`
verbose=
noprompt=
if [ -z "$myfqdn" ]; then
	myfqdn="localhost"
fi

function usage() {
	echo "Usage:"
	echo "$0 [-h | --help] [-v] [-d <dnsdomain>] [-p <password>] [-y]"
	echo
	echo "-h | --help    : shows this help"
	echo "-v             : verbose mode"
	echo "-d <dnsdomain> : use <dnsdomain> for dns domain"
	echo "-p <password>  : use <password> for LDAP Admin password"
	echo 
	echo "-y             : assume default answer in all prompts "
	echo "                 except the password one"
}

function echo_v() {
	if [ -n "$verbose" ]; then
		echo "== $@"
	fi
}

# output: stdout: example.com or the possible detected domain
function detect_domain() {
	mydomain=`hostname -d`
	if [ -z "$mydomain" ]; then
		mydomain="example.com"
	fi
	echo "$mydomain"
	return 0
}

# output: stdout: name of temporary file
# *exits* if error
function make_temp() {
	tmpfile=`mktemp ${TMP:-/tmp}/mandriva-dit.XXXXXXXXXXXX`
	if [ -f "$tmpfile" ]; then
		echo "$tmpfile"
		return 0
	else
		echo "error while making temporary file" >&2
		exit 1
	fi
}

# $1: domain
# returns standard dc=foo,dc=bar suffix on stdout
function calc_suffix() {
	old_ifs=${IFS}
	IFS="."
	for component in $1; do
		result="$result,dc=$component"
	done
	IFS="${old_ifs}"
	echo "${result#,}"
	return 0
}


# $1: directory where the LDAP database is
# output (stdout): backup dir of the previous database
function clean_database() {
	backupdir="/var/lib/ldap.$now"
	cp -a "$1" "$backupdir" 2>/dev/null
	if [ "$?" -ne "0" ]; then
		echo "Error, could not make a backup copy of the"
		echo "current LDAP database, aborting..."
		echo
		echo "(not enough disk space?)"
		echo
		exit 1
	fi
	rm -f "$1"/{*.bdb,log.*,__*,alock}
	echo "$backupdir"
	return 0
}

# $1: *file* to be backed up
# output (stdout): backup filename
function mybackup() {
	if [ ! -f "$1" ]; then
		echo "Internal error, $1 has to be a file" >&2
		echo "Aborting" >&2
		exit 1
	fi
	newname="$1.$now"
	cp -a "$1" "$newname"
	echo "$newname"
	return 0
}

while [ -n "$1" ]; do
	case "$1" in
		-h | --help)
		usage
		exit 1
		;;
		-v)
		verbose=1
		shift
		;;
		-d)
		shift
		if [ -n "$1" -a "${1##-}" != "${1}" -o -z "${1}" ]; then
			echo "Error, -d requires an argument"
			exit 1
		fi
		mydomain="$1"
		shift
		;;
		-p)
		shift
		if [ -n "$1" -a "${1##-}" != "${1}" -o -z "${1}" ]; then
			echo "Error, -p requires an argument"
			exit 1
		fi
		mypass="$1"
		shift
		;;
		-y)
		noprompt=1
		shift
		;;
	esac
done

echo_v
echo_v "Running in verbose mode"
echo_v

if [ -z "$mydomain" ]; then
	mydomain=`detect_domain`
	if [ -z "$noprompt" ]; then
		echo "Please enter your DNS domain name [$mydomain]:"
		read inputdomain
		if [ -n "$inputdomain" ]; then
			mydomain="$inputdomain"
		fi
	fi
fi
mysuffix=`calc_suffix $mydomain`

if [ -z "$mypass" ]; then
	echo
	echo "Administrator account"
	echo
	echo "The administrator account for this directory is"
	echo "uid=LDAP Admin,ou=System Accounts,$mysuffix"
	echo
	echo "Please choose a password for this account:"
	while /bin/true; do
		pass=`$SLAPPASSWD -h {SSHA}`
		if [ -n "$pass" ]; then
			break
		fi
	done
else
	pass=`$SLAPPASSWD -h {SSHA} -s "$mypass"`
	if [ "$?" -ne "0" ]; then
		echo "Error at generating password, exiting"
		exit 1
	fi
fi

# confirmation
echo
echo
echo "Summary"
echo "======="
echo
echo "Domain:        $mydomain"
echo "LDAP suffix:   $mysuffix"
echo "Administrator: uid=LDAP Admin,ou=System Accounts,$mysuffix"
echo
if [ -z "$noprompt" ]; then
	echo "Confirm? (Y/n)"
	read val
	if [ "$val" = "n" -o "$val" = "N" ]; then
		echo
		echo "Cancelled."
		exit 1
	fi
fi

# let's do it

# first, slapd.conf
myslapdconf=`make_temp`

echo_v "Creating slapd.conf..."
cat $slapd_conf_template | sed -e "s/@SUFFIX@/$mysuffix/g;" > $myslapdconf
chmod 0640 $myslapdconf
chgrp ldap $myslapdconf

# now, /etc/openldap/ldap.conf
myldapconf=`make_temp`
echo_v "Creating ldap.conf..."
cat /etc/openldap/ldap.conf | \
	sed -e "s/^BASE[[:blank:]]\+.*/BASE $mysuffix/g;\
	s/^HOST[[:blank:]]\+.*/HOST $myfqdn/g;\
	s@^URI[[:blank:]]\+.*@URI ldap://$myfqdn@g" \
	> $myldapconf
if ! grep -qE '^(HOST|URI)' $myldapconf; then
	echo "URI ldap://$myfqdn" >> $myldapconf
fi
if ! grep -qE '^BASE' $myldapconf; then
	echo "BASE $mysuffix" >> $myldapconf
fi
chmod 0644 $myldapconf

# ACL file
echo_v "Creating acl file..."
cat $acl_template | sed -e "s/@SUFFIX@/$mysuffix/g" > $acl_file
chmod 0640 $acl_file
chgrp ldap $acl_file

# test
echo_v "Testing configuration with temporary files..."
$SLAPTEST -u -f $myslapdconf
if [ "$?" -ne "0" ]; then
	echo "ERROR"
	echo "OpenLDAP configuration file was generated with errors"
	echo "Aborting. File used was $myslapdconf"
	rm -f $myldapconf
	exit 1
fi

# load
echo_v "Test succeeded, creating LDIF file for database loading..."
myldif=`make_temp`
cat $base_ldif_template | sed -e "\
	s/@SUFFIX@/$mysuffix/g;\
	s/@DC@/${mydomain%%.[a-zA-Z0-9]*}/g;\
	s/@DOMAIN@/${mydomain}/g;\
	s|@ldapadmin_password@|$pass|g" > $myldif

# dry run first
echo_v "Attempting to test-load the database..."
$SLAPADD -u -f $myslapdconf < $myldif
if [ "$?" -ne "0" ]; then
	echo "ERROR"
	echo "Database loading failed during test run."
	echo "Ldif file used:       $myldif"
	echo "slapd.conf file used: $myslapdconf"
	echo
	echo "Exiting"
	rm -f $myldapconf
	exit 1
fi

# let's go for real now
echo_v "Everything ok, doing it for real now."
echo "Stopping ldap service"
/sbin/service ldap stop > /dev/null 2>&1 || :
echo_v "Backing up existing files..."
backup_db=`clean_database /var/lib/ldap`
backup_slapd_conf=`mybackup /etc/openldap/slapd.conf`
backup_ldap_conf=`mybackup /etc/openldap/ldap.conf`
echo_v "Writing /etc/openldap/slapd.conf and /etc/openldap/ldap.conf..."
cat $myslapdconf > /etc/openldap/slapd.conf; rm -f $myslapdconf
cat $myldapconf > /etc/openldap/ldap.conf; rm -f $myldapconf

echo_v "Loading database..."
$SLAPADD < $myldif
if [ "$?" -ne "0" ]; then
	echo "Something went wrong while initializing the database"
	echo "Aborting. Your previous database is at $backup_db"
	echo "Your original /etc/openldap/{slapd,ldap}.conf files"
	echo "were backed up as $backup_slapd_conf and"
	echo "$backup_ldap_conf, respectively."
	exit 1
fi

echo "Finished, starting ldap service"
/sbin/service ldap start
echo
echo "Your previous database directory has been backed up as $backup_db"
echo "All files that were backed up got the suffix \"$now\"."
echo
