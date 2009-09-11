#!/bin/bash

if [ "`id -u`" != "0" ]; then
	echo "Error, must be root user"
	exit 1
fi

LDAPWHOAMI="ldapwhoami -H ldapi:/// -Y EXTERNAL -Q"
LDAPADD="ldapadd -H ldapi:/// -Y EXTERNAL -Q"
LDAPMODIFY="ldapmodify -H ldapi:/// -Y EXTERNAL -Q"

function distro_guess()
{
#$ cat /etc/lsb-release 
#DISTRIB_ID=Ubuntu
#DISTRIB_RELEASE=8.04
#DISTRIB_CODENAME=hardy
#DISTRIB_DESCRIPTION="Ubuntu 8.04"
    if [ -r "/etc/lsb-release" ]; then
        source /etc/lsb-release
    else
        echo "Can't guess distro name (no /etc/lsb-release or it's not readable)"
        exit 1
    fi
    if [ -z "$DISTRIB_ID" -o -z "$DISTRIB_RELEASE" ]; then
        echo "No DISTRIB_ID or DISTRIB_RELEASE variable(s) in /etc/lsb-release"
        exit 1
    fi
    DISTRIB_ID=`echo $DISTRIB_ID | tr A-Z a-z`
    export DISTRIB_ID DISTRIB_RELEASE
    echo $DISTRIB_ID
    return 0
}

function ubuntu_setup()
{
    if [ -x /usr/sbin/invoke-rc.d ]; then
        SERVICE="/usr/sbin/invoke-rc.d slapd"
    else
        SERVICE="/etc/init.d/slapd"
    fi
    export root="/usr/share/slapd/openldap-dit"
    export databases="$root/databases"
    export schemas="$root/schemas"
    export acls="$root/acls"
    export modules="$root/modules"
    export overlays="$root/overlays"

    for package in slapd ldap-utils libsasl2-modules; do
        if ! dpkg -l $package 2>/dev/null | grep -q ^ii; then
            echo "Error, please install package $package"
            exit 1
        fi
    done

    return 0
}

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

# test if sasl external works and maps us to something
function test_auth() {
    out=$($LDAPWHOAMI)
    [ "$?" -ne "0" ] && return 1
    # XXX - too specific for ubuntu's ldap deployment...
    # a better test would be slapacl, but I couldn't get it
    # to work
    if [ "$out" = "dn:cn=localroot,cn=config" ]; then
        return 0
    else
        return 1
    fi
}

function get_admin_password() {
	echo
	echo "Administrator account"
	echo
	echo "The administrator account for this directory is"
	echo "uid=LDAP Admin,ou=System Accounts,$mysuffix"
	echo
	echo "Please choose a password for this account:"
	while /bin/true; do
        echo "New password: "
        stty -echo
        read pass1
        stty echo
        if [ -z "$pass1" ]; then
            echo "Error, password cannot be empty"
            echo
            continue
        fi
        echo "Repeat new password: "
        stty -echo
        read pass2
        stty echo
        if [ "$pass1" != "$pass2" ]; then
            echo "Error, passwords don't match"
            echo
            continue
        fi
        pass="$pass1"
        break
	done
    if [ -n "$pass" ]; then
        return 0
    fi
    return 1
}

function check_result() {
    if [ "$1" -ne "0" ]; then
        echo "ERROR, aborting"
        exit 1
    else
        echo "Succeeded!"
    fi
}

function add_modules() {
    return 0
}

function add_schemas() {
    return 0
}

function add_db () {
    return 0
}

function modify_frontend_acls() {
    return 0
}

function modify_config_acls() {
    return 0
}

function add_overlays() {
    return 0
}

function populate_db() {
    return 0
}

function set_admin_password() {
    return 0
}


now=`date +%s`
myfqdn=`hostname -f`
verbose=
noprompt=
if [ -z "$myfqdn" ]; then
	myfqdn="localhost"
fi
distro=`distro_guess`
${distro}_setup

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


# testing
echo "Testing administrative access to local ldap server"
test_auth
if [ "$?" -eq "0" ]; then
    echo "Success!"
else
    echo "FAILURE!"
    echo "Command \"$LDAPWHOAMI\" failed"
    exit 1
fi

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
    get_admin_password
else
	pass="$mypass"
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

# steps:
# - add modules
# - add schema
# - add db + its acls
# - modify frontend acls
# - modify config acls
# - add overlays
# - populate db
# - set password for admin

add_modules
check_result $?

add_schemas
check_result $?

add_db
check_result $?

modify_frontend_acls
check_result $?

modify_config_acls
check_result $?

add_overlays
check_result $?

populate_db
check_result $?

set_admin_password
check_result $?

echo
echo "Finished, enjoy!"
echo

