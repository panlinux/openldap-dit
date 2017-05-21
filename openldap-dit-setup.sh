#!/bin/bash

if [ "`id -u`" != "0" ]; then
    echo "Error, must be root user"
    exit 1
fi

LDAPWHOAMI="ldapwhoami -H ldapi:/// -Y EXTERNAL -Q"
LDAPADD="ldapadd -H ldapi:/// -Y EXTERNAL -Q"
LDAPMODIFY="ldapmodify -H ldapi:/// -Y EXTERNAL -Q"
LDAPPASSWD="ldappasswd -H ldapi:/// -Y EXTERNAL -Q"


ubuntu_setup() {
    export root="/usr/share/slapd/openldap-dit"
    export databases_dir="$root/databases"
    export schemas_dir="$root/schemas"
    export acls_dir="$root/acls"
    export modules_dir="$root/modules"
    export overlays_dir="$root/overlays"
    export contents_dir="$root/contents"

    for package in slapd ldap-utils libsasl2-modules; do
        if ! dpkg -l $package 2>/dev/null | grep -q ^ii; then
            echo "Error, please install package $package"
            exit 1
        fi
    done

    return 0
}

usage() {
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

echo_v() {
    if [ -n "$verbose" ]; then
        echo "== $@"
    fi
}

# output: stdout: example.com or the possible detected domain
detect_domain() {
    mydomain=`hostname -d`
    if [ -z "$mydomain" ]; then
        mydomain="example.com"
    fi
    echo "$mydomain"
    return 0
}

# $1: domain
# returns standard dc=foo,dc=bar suffix on stdout
calc_suffix() {
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
test_auth() {
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

get_admin_password() {
    echo
    echo "Administrator account"
    echo
    echo "The administrator account for this directory is"
    echo "uid=LDAP Admin,ou=System Accounts,$mysuffix"
    echo
    echo "Please choose a password for this account:"
    while /bin/true; do
        echo -n "New password: "
        stty -echo
        read pass1
        stty echo
        echo
        if [ -z "$pass1" ]; then
            echo "Error, password cannot be empty"
            echo
            continue
        fi
        echo -n "Repeat new password: "
        stty -echo
        read pass2
        stty echo
        echo
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

check_result() {
    if [ "$1" -ne "0" ]; then
        echo "ERROR, aborting"
        exit 1
    else
        echo "Succeeded!"
    fi
}

# $1: descriptive text of what is being added
# $2: directory where the files are
# $3: optional sed expression to use
add_ldif() {
    echo "Adding $1..."
    for n in $2/*.ldif; do
        if [ -z "$n" ]; then
            echo "Error, no file to use!"
            return 1
        fi
        if [ -z "$3" ]; then
            cat "$n" | $LDAPADD
        else
            cat "$n" | sed -e "$3" | $LDAPADD
        fi
        if [ "$?" -ne "0" ]; then
            echo "Error using \"$n\", aborting"
            exit 1
        fi
    done
    return 0
}

# $1: descriptive text of what is being added
# $2: directory where the files are
# $3: optional sed expression to use
modify_ldif() {
    echo "Modifying $1..."
    for n in $2/*.ldif; do
        if [ -z "$n" ]; then
            echo "Error, no file to use!"
            return 1
        fi
        if [ -z "$3" ]; then
            cat "$n" | $LDAPMODIFY
        else
            cat "$n" | sed -e "$3" | $LDAPMODIFY
        fi
        if [ "$?" -ne "0" ]; then
            echo "Error using \"$n\", aborting"
            return 1
        fi
    done
    return 0
}

add_modules() {
    add_ldif "modules" "$modules_dir"
    return 0
}

add_schemas() {
    add_ldif "schemas" "$schemas_dir"
    return 0
}

add_db () {
    add_ldif "database" "$databases_dir" "s/@SUFFIX@/$mysuffix/g"
    return 0
}

modify_acls() {
    modify_ldif "ACLs" "$acls_dir" "s/@SUFFIX@/$mysuffix/g"
    return 0
}

add_overlays() {
    add_ldif "overlays" "$overlays_dir" "s/@SUFFIX@/$mysuffix/g"
    return 0
}

populate_db() {
    add_ldif "populated database" "$contents_dir" "s/@SUFFIX@/$mysuffix/g;s/@DC@/${mydomain%%.[a-zA-Z0-9]*}/g;s/@DOMAIN@/${mydomain}/g"
    return 0
}

set_admin_password() {
    echo "Setting the admin password..."
    # XXX - password will show up briefly in the command line and process
    # list
    $LDAPPASSWD -s "$pass" "uid=LDAP Admin,ou=System Accounts,$mysuffix"
    return $?
}


now=`date +%s`
myfqdn=`hostname -f`
verbose=
noprompt=
if [ -z "$myfqdn" ]; then
    myfqdn="localhost"
fi
ubuntu_setup

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

modify_acls
check_result $?

add_overlays
check_result $?

populate_db
check_result $?

set_admin_password
check_result $?

echo
echo "Finished, doing one last restart..."
service slapd restart
check_result $?

echo
echo "Done, enjoy!"
echo
echo "Remember: this is your administrator bind dn:"
echo "uid=LDAP Admin,ou=System Accounts,$mysuffix"
echo
echo "You can use it in double quotes in the command line, like:"
echo "ldapwhoami -x -D \"uid=LDAP Admin,ou=System Accounts,$mysuffix\" -W "
echo


