#!/bin/sh

set -e
set -x

# Install the public root ssh key
mkdir -p /target/root/.ssh # Use -p, since on bookworm, the dir exists
wget -O /target/root/.ssh/authorized_keys http://apt.wikimedia.org/autoinstall/ssh/authorized_keys
chmod go-rwx /target/root/.ssh/authorized_keys

# lsb-release: allows conditionals in this script on in-target release codename
apt-install lsb-release
LSB_RELEASE=$(chroot /target /usr/bin/lsb_release --codename --short)

# On Bookworm install a Puppet 5 agent backport, otherwise we can't renew the host cert
# https://phabricator.wikimedia.org/T330495
if [ "${LSB_RELEASE}" = "bookworm" ]; then
  BASE_REPO="[signed-by=/etc/apt/keyrings/Wikimedia_APT_repository.gpg] http://apt.wikimedia.org/wikimedia bookworm-wikimedia component"
  printf 'deb %s/puppet5\n' "$BASE_REPO" > /target/etc/apt/sources.list.d/component-puppet5.list
  in-target apt-get update
  apt-install -y --force-yes puppet=5.5.22-2+deb12u3
  apt-install openssh-server lldpd
  apt-install -y ruby-sorted-set
else
  # openssh-server: to make the machine accessible
  # puppet: because we'll need it soon anyway
  # lldpd: announce the machine on the network
  apt-install openssh-server puppet lldpd
fi

# nvme-cli: on machines with NVMe drives, this allows late_command to change
# LBA format below
apt-install nvme-cli

# Change /etc/motd to read the auto-install date
chroot /target /bin/sh -c 'echo $(cat /etc/issue.net) auto-installed on $(date). > /etc/motd.tail'

# Disable IPv6 privacy extensions before the first boot
[ -f /target/etc/sysctl.d/10-ipv6-privacy.conf ] && rm -f /target/etc/sysctl.d/10-ipv6-privacy.conf

# Format any edge cache node NVMe drives as 4K block size for direct use as a
# single partition for ats-be cache (we currently have a mix of nodes with 0,
# 1, or 2 such drives).
case $(hostname) in
    cp[1-9][0-9][0-9][0-9]|sretest2002)
	# Starting with bullseye the fdisk udeb is no longer enabled by default
	anna-install fdisk-udeb
        for nvmedev in /dev/nvme?n1; do
            in-target /usr/sbin/nvme format "$nvmedev" -l 2
            echo ';' | /usr/sbin/sfdisk "$nvmedev"
        done
    ;;
esac

# These snapshot hosts run Buster, but have a controller only supported on 5.10, so they use
# a backported d-i component T334955
case $(hostname) in
    snapshot101[67]*)
	apt-install linux-image-5.10-amd64
    ;;
esac

# Temporarily pre-provision swift user at a fixed UID on new installs.
# Once T123918 is resolved and swift is the same uid/gid everywhere, the
# 'admin' puppet module can take over.
# When reimaging backends, we need to make sure the swift uid/gid match
# what's on the swift filesystems; do this by attempting to mount sde1
# (present on all the relevant hosts) and inspecting the ownership of
# objects therein. Once everything is standard, all this bodgery can go.
case `hostname` in \
    ms-be[12]*)
	# needed for stat
	apt-install coreutils
	mp=$(mktemp -d)
	if [ -b /dev/sde1 ] && mount -t xfs -o ro /dev/sde1 "$mp"; then
	    swiftuid=$(/target/usr/bin/stat -c %u "${mp}/objects") || swiftuid=""
	    swiftgid=$(/target/usr/bin/stat -c %g "${mp}/objects") || swiftgid=""
	    umount "$mp"
	fi
	rmdir "$mp"
	;;
esac
case $(hostname) in \
    ms-be[12]*|ms-fe[12]*|thanos-fe[12]*|thanos-be[12]*)
	[ -z "$swiftuid" ] && swiftuid=902
	[ -z "$swiftgid" ] && swiftgid=902
	in-target /usr/sbin/groupadd --gid "$swiftgid" --system swift
	in-target /usr/sbin/useradd --gid "$swiftgid" --uid "$swiftuid" --system --shell /bin/false \
		  --create-home --home /var/lib/swift swift
	;;
esac

in-target /usr/bin/puppet config set --section main vardir /var/lib/puppet
in-target /usr/bin/puppet config set --section main rundir /var/run/puppet
in-target /usr/bin/puppet config set --section main factpath /var/lib/puppet/lib/facter

# Configure ipv6 (sorry this is not pretty)
IFACE=$(ip -4 route list 0/0 | cut -d ' ' -f 5 | head -1)
# IPv4 with : not '.'
IP="$(ip -o -4 address show dev $IFACE | tr -s ' ' | cut -d ' ' -f 4 | cut -d '/' -f 1| tr '.' ':')"
IP6_SLAAC="$(ip -o -6 addr show dev ${IFACE} | tr -s ' ' | cut -d ' ' -f4 | head -1)"

printf '\tpre-up /sbin/ip token set ::%s dev %s\n' "${IP}" "${IFACE}" >> /target/etc/network/interfaces
if [ -z "${IP6_SLAAC}" ]
then
  # No global ipv6 address
  PREFIX="NO_IPV6"
elif test "${IP6_SLAAC#*::}" != "${IP6_SLAAC}"
then
  # Current address is compressed
  PREFIX="${IP6_SLAAC%%::*}::"
else
  PREFIX="$(printf '%s' "${IP6_SLAAC}" | cut -d: -f1,2,3,4):"
fi
if [ "${PREFIX}" != "NO_IPV6" ]
then
  IP6="${PREFIX}${IP}"
  printf '\tup ip addr add %s/64 dev %s\n' "${IP6}" "${IFACE}" >> /target/etc/network/interfaces
fi
