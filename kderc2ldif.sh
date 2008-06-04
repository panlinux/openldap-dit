#!/bin/bash

# License: GPL
# Copyright: Mandriva (c) 2007

# This script will read a given KDE "rc" file and
# write its ldif representation to stdout according
# to kde.schema. See http://bugs.kde.org/show_bug.cgi?id=101716
# Example: ./kderc2ldif.sh konquerorrc

BASE="dc=example,dc=com"
KDEBASE="ou=KDEConfig,$BASE"
PROFILE="default"

function usage() {
	echo "Usage: $0 <kderc file>"
}


if [ "$#" -ne "1" ]; then
	usage
	exit 1
fi

file="$1"

if [ ! -e "$file" ]; then
	echo "File \"$file\" not found."
	exit 1
fi


cat <<EOF
dn: cn=$file,ou=$PROFILE,$KDEBASE
cn: $file
objectClass: appConfig
description: KDE configuration for $file
EOF


{ while read line; do
	# skip empty lines or lone [$i]
	if [ -z "$line" ]; then
		continue
	fi
	if [ "$line" = "[\$i]" -a -z "$globalimmutable" ]; then
		echo "immutable: TRUE"
		globalimmutable="true"
		continue
	fi
	# look for section
	if [ "${line:0:1}" = "[" ]; then
		if [ "${line:$((${#line}-4))}" = "[\$i]" -a -z "$globalimmutable" ]; then
			immutable="true"
		fi
		line="${line%\[\$i\]}"
		temp=${line:1}
		section=${temp/]/}
		echo ""
		echo "dn: cn=$section,cn=$file,ou=$PROFILE,$KDEBASE"
		echo "cn: $section"
		echo "objectClass: appConfigSection"
		echo "appName: $file"
		if [ "$immutable" = "true" ]; then
			echo "immuteable: TRUE"
		fi
	elif [ -n "$section" ]; then
		echo "appConfigEntry: $line"
	fi
done } < "$file"
echo


