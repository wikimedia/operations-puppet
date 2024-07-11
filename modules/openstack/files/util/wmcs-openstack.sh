#!/bin/bash

if [ "$(id -u)" != "0" ] ; then
	echo "E: need root!" >&2
	exit 1
fi

export OS_CLOUD=novaadmin
openstack "$@"
