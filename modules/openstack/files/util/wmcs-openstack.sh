#!/bin/bash

if [ "$(id -u)" != "0" ] ; then
	echo "E: need root!" >&2
	exit 1
fi

# Weird workaround to make sure we get the right clouds.yaml
cd /root/.config/openstack

export OS_CLOUD=novaadmin
openstack "$@"
