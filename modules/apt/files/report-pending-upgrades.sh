#!/bin/bash

if [ "$(id -u)" != "0" ] ; then
	echo "E: root required" >&2
	exit 1
fi

get_binary()
{
	BINARY=$(which $1)
	if [ ! -x "$BINARY" ] ; then
		echo "E: no $1 binary found" >&2
		exit 1
	fi
	echo $BINARY
}

set -e
APT_GET=$(get_binary apt-get)
APT_SHOW_VERSIONS=$(get_binary apt-show-versions)
UNATTENDED_UPGRADES=$(get_binary unattended-upgrades)
set +e

echo "I: $0 running on $(uname -n)"
echo "I: updating package cache"
$APT_GET update >/dev/null

APT_SHOW_VERSIONS_OUTPUT=$($APT_SHOW_VERSIONS | grep upgradeable | sort -t / -k 2)
n1=$(echo "$APT_SHOW_VERSIONS_OUTPUT" | grep -v ^$ | wc -l)

UNATTENDED_UPGRADES_OUTPUT=$($UNATTENDED_UPGRADES --dry-run -v -d | grep "Packages that will be upgraded" | awk -F':' '{print $2}' | grep -v ^[[:space:]]*$)
n2=$(echo "$UNATTENDED_UPGARDES_OUTPUT" | grep -v ^$ | wc -l)

if [ "$n1" != "0" ] ; then
	sources=$(echo "$APT_SHOW_VERSIONS_OUTPUT" | awk -F'/' '{print $2}' | awk -F' ' '{print $1}' | uniq)
	for src in $sources ; do
		src_output=$(echo "$APT_SHOW_VERSIONS_OUTPUT" | grep $src)
		n3=$(echo "$src_output" | wc -l)
		echo "I: upgradeable packages from ${src}: $n3"
		echo
		echo "$src_output" | sed -e 's/^/  /'
		echo
	done
fi

if [ "$n2" != "0" ] ; then
	echo "I: upgradeable packages by unattended-upgrades: $n2"
	echo
	echo "$UNATTENDED_UPGARDES_OUTPUT" | sed -e 's/^/  /'
	echo
fi
echo "I: $n1 upgradeable packages, $n2 upgradeable packages by unatteneded-upgrades"
