#!/bin/sh

set -e
set -x

# Install the public root ssh key
mkdir -p /target/root/.ssh # Use -p, since on bookworm, the dir exists
wget -O /target/root/.ssh/authorized_keys http://apt.wikimedia.org/autoinstall/ssh/authorized_keys
chmod go-rwx /target/root/.ssh/authorized_keys
PUPPET_VERSION_PATH="/tmp/puppet_version"
i=1
while [ "${i}" -le  5 ]; do
  if [ -f "${PUPPET_VERSION_PATH}" ]; then
    PUPPET_VERSION=$(cat "${PUPPET_VERSION_PATH}")
    if [ -n "${PUPPET_VERSION}" ]; then
      break
    fi
  fi
  echo "Puppet version to install not found at ${PUPPET_VERSION_PATH}"
  sleep 10
  i=$((i + 1))
done

if [ "$PUPPET_VERSION" -ne 5 ] && [ "$PUPPET_VERSION" -ne 7 ]; then
  printf "Unable to determine PUPPET_VERSION (%s) will default to 5\n" "$PUPPET_VERSION"
  PUPPET_VERSION=5
fi

# lsb-release: allows conditionals in this script on in-target release codename
apt-install lsb-release
LSB_RELEASE=$(chroot /target /usr/bin/lsb_release --codename --short)
BASE_REPO="[signed-by=/etc/apt/keyrings/Wikimedia_APT_repository.gpg] http://apt.wikimedia.org/wikimedia ${LSB_RELEASE}-wikimedia component"
if [ "$PUPPET_VERSION" -eq 7 ]; then
  case "${LSB_RELEASE}" in
    "bookworm")
      printf 'Package: puppet\nPin: release l=Debian\nPin-Priority: 1003\n' > /target/etc/apt/preferences.d/puppet.pref
      ;;
    "bullseye")
      printf 'deb %s/puppet7\n' "$BASE_REPO" > /target/etc/apt/sources.list.d/component-puppet7.list
      ;;
  esac
fi
in-target apt-get update
# openssh-server: to make the machine accessible
# lldpd: announce the machine on the network
# puppet: will be needed soon
apt-install openssh-server lldpd puppet

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
if [ "${PUPPET_VERSION}" -eq 7 ]; then
  # We currently have an expired root crl in our crl T340543
  in-target /usr/bin/puppet config set --section main certificate_revocation leaf
  in-target /usr/bin/puppet config set --section agent use_srv_records true
  # Send everything to eqiad instead of trying to calculate the correct site
  in-target /usr/bin/puppet config set --section agent srv_domain eqiad.wmnet
fi

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
