#!/bin/bash

# This script is meant to be executed by reprepro, is used to filter packages
# The only reason this exists is to avoid having an overly long line in the
# conf/updates files (ListShellHook). Instead, this script can be used in the
# ListHook to filter the resulting Package file. Thus, this script is
# specifically crafter to be run by reprepro. Not intended to be run by hand.
#
# Arguments are 2 files:
#   * an unfiltered 'Packages' file (OLD_FILE)
#   * filtered packages file (NEW_FILE)
#
# If you are reusing this code, you just need to update the PKGS variable with
# one package name per line.
#
# In this concrete case, for openstack packages @ jessie-backports, we used:
#
# $ dpkg-query -W -f='\${source:Package} \${source:Version}\n' | grep ~bpo8 \
#         | awk -F' ' '{print \$1}' | sort | uniq
#
# You can run the command in cumin (scape the $ symbols), like this:
#
# $ sudo cumin --force -p 0 A:cloud-eqiad1 "cmd" 2>/dev/null | sort | uniq
#
# You will likely need to manually inspect this generated list of source
# packages though, and skip other unrelated cumin output bits.

#
# packages skipped on purpose, because they induce conflicts in the apt
# resolver when using in a system with stretch repos enabled:
#
# libvirt (libvit-daemon-system and friends)
# ceph (librados2, librbd1)
# qemu (qemu-system, qemu-system-*)
# python-mysqldb
# pulseaudio (libpulse0)
# seabios
# python-dogpile.cache
# python-psutil
# gdb
# facter

PKGS="alabaster
alembic
apparmor
brltty
contextlib2
dbconfig-common
designate
device-tree-compiler
diamond
dnspython
firmware-nonfree
flask
glance
ifupdown
jinja2
jquery
kazoo
keystone
kombu
lapack
libcacard
libfastjson
liblognorm
libseccomp
libsodium
linux-base
migrate
msgpack-python
neutron
nova
openbios
open-iscsi
open-isns
openssl
pdns-recursor
postgresql-9.6
puppet
pyasn1
pyinotify
pyopenssl
python-amqp
python-automaton
python-cachetools
python-castellan
python-cffi
python-cinderclient
python-concurrent.futures
python-cryptography
python-dateutil
python-debtcollector
python-designateclient
python-editor
python-eventlet
python-fasteners
python-fixtures
python-funcsigs
python-functools32
python-futurist
python-glanceclient
python-glance-store
python-greenlet
python-idna
python-imagesize
python-ipaddress
python-iso8601
python-jsonschema
python-keyring
python-keystoneauth1
python-keystoneclient
python-keystonemiddleware
python-ldap3
python-linecache2
python-memcache
python-monotonic
python-netaddr
python-networkx
python-neutronclient
python-neutron-lib
python-novaclient
python-numpy
python-openstackclient
python-openstacksdk
python-os-brick
python-os-client-config
python-oslo.cache
python-oslo.concurrency
python-oslo.config
python-oslo.context
python-oslo.db
python-oslo.i18n
python-oslo.log
python-oslo.messaging
python-oslo.middleware
python-oslo.policy
python-oslo.reports
python-oslo.rootwrap
python-oslo.serialization
python-oslo.service
python-oslo.utils
python-oslo.versionedobjects
python-osprofiler
python-os-win
python-passlib
python-pbr
python-pecan
python-pika
python-pika-pool
python-positional
python-pycadf
python-pymemcache
python-pymysql
python-pysaml2
python-redis
python-repoze.who
python-requestsexceptions
python-requests-kerberos
python-retrying
python-semantic-version
python-setuptools
python-swiftclient
python-taskflow
python-testtools
python-tooz
python-traceback2
python-urllib3
python-warlock
python-webob
python-wrapt
python-wsme
pyudev
q-text-as-data
quickstack
requests
routes
rsyslog
ruby-deep-merge
ryu
six
smartmontools
sphinx
sqlalchemy
sqlite3
stevedore
suds
underscore
unittest2
voluptuous
websockify"

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
