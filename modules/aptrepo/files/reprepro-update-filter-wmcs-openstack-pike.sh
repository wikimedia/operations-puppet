#!/bin/bash

# This script is meant to be executed by reprepro, is used to filter packages.
# The only reason this exists is to avoid having an overly long line in the
# conf/updates files (ListShellHook). Instead, this script can be used in the
# ListHook to filter the resulting Package file. Thus, this script is
# specifically crafted to be run by reprepro. Not intended to be run by hand
# unless you are testing it.
#
# Arguments are 2 files:
#   * an unfiltered 'Packages' file (OLD_FILE)
#   * filtered packages file (NEW_FILE)
#
# If you are reusing this code, you just need to update the PKGS variable with
# one package name per line. Packages are SOURCE packages, not binary.
#

PKGS="alembic
designate
glance
keystone
neutron
nova
pyroute2
python-cliff
python-debtcollector
python-keystoneauth1
python-keystoneclient
python-keystonemiddleware
python-monasca-statsd
python-neutron-lib
python-os-brick
python-oslo.config
python-oslo.context
python-oslo.db
python-oslo.log
python-oslo.messaging
python-oslo.policy
python-oslo.privsep
python-oslo.rootwrap
python-oslo.utils
python-os-vif
python-os-win
python-os-xenapi
python-swiftclient
python-taskflow
python-tenacity
python-tinyrpc
python-tooz
python-weakrefmethod
python-wsgi-intercept
ryu
jinja2
migrate
msgpack-python
python-oslo.i18n
python-oslo.serialization
python-oslo.middleware
requests
testresources
vine
python-amqp
python-webob
kombu
python-tenacity"

OLD_FILE="$1"
NEW_FILE="$2"

if [ -z "$OLD_FILE" ] || [ -z "$NEW_FILE" ] ; then
	echo "${0}: ERROR: wrong input arguments. Expected: <old file> <new file>" >&2
	exit 1
fi

if [ ! -r "$OLD_FILE" ] ; then
	echo "${0}: ERROR: can't read $OLD_FILE" >&2
	exit 1
fi

GREP_DCTLR="$(which grep-dctrl)"
if [ ! -x "$GREP_DCTLR" ] ; then
	echo "${0}: ERROR: grep-dctrl binary not found." >&2
	exit 1
fi

FILTER="^($(echo $PKGS | tr [:blank:] \|))$"
$GREP_DCTLR -e -S $FILTER < $OLD_FILE > $NEW_FILE || [ $? -eq 1 ]
