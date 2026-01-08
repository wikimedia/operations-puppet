#!/bin/sh

set -e
set -x

# Install the public root ssh key
mkdir -p /target/root/.ssh # Use -p, since on bookworm, the dir exists
wget -O /target/root/.ssh/authorized_keys http://apt.wikimedia.org/autoinstall/ssh/authorized_keys
chmod go-rwx /target/root/.ssh/authorized_keys

#This was used in the P5-P7 transition, currently unused, but maybe needed later, so we keep it around for now
#PUPPET_VERSION_PATH="/tmp/puppet_version"
#i=1
#while [ "${i}" -le  10 ]; do
#  if [ -f "${PUPPET_VERSION_PATH}" ]; then
#    PUPPET_VERSION=$(cat "${PUPPET_VERSION_PATH}")
#    if [ -n "${PUPPET_VERSION}" ]; then
#      break
#    fi
#  fi
#  echo "Puppet version to install not found at ${PUPPET_VERSION_PATH}"
#  sleep 30
#  i=$((i + 1))
#done

# lsb-release: allows conditionals in this script on in-target release codename
apt-install lsb-release
LSB_RELEASE=$(chroot /target /usr/bin/lsb_release --codename --short)
BASE_REPO="http://apt.wikimedia.org/wikimedia ${LSB_RELEASE}-wikimedia component"
case "${LSB_RELEASE}" in
  "trixie")
    printf 'deb %s/puppet7\n' "$BASE_REPO" > /target/etc/apt/sources.list.d/component-puppet7.list
    printf 'Package: ruby-concurrent ruby libruby puppet puppet-agent\nPin: release c=component/puppet7\nPin-Priority: 1002\n' > /target/etc/apt/preferences.d/puppet.pref
    ;;
  "bookworm")
    printf 'Package: puppet\nPin: release l=Debian\nPin-Priority: 1003\n' > /target/etc/apt/preferences.d/puppet.pref
    ;;
  "bullseye")
    printf 'deb %s/puppet7\n' "$BASE_REPO" > /target/etc/apt/sources.list.d/component-puppet7.list
    ;;
esac
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
# To check for supported LBA formats (to use with the -l option) use
# /usr/sbin/nvme id-ns <NVME_DEVICE> | grep ^lbaf
# See https://phabricator.wikimedia.org/T392851#11123297 for more details

# Default for all cp hosts
LBA_FORMAT_NUMBER=2
case $(hostname) in
    cp204[3-9]|cp205[0-8])
        # New codfw hosts
        LBA_FORMAT_NUMBER=1
        ;;
esac

case $(hostname) in
    cp[1-9][0-9][0-9][0-9]|sretest2002)
        anna-install fdisk-udeb
        for nvmedev in /dev/nvme?n1; do
            in-target /usr/sbin/nvme format "$nvmedev" -l $LBA_FORMAT_NUMBER
            echo ';' | /usr/sbin/sfdisk "$nvmedev"
        done
        ;;
esac

in-target /usr/bin/puppet config set --section main vardir /var/lib/puppet
in-target /usr/bin/puppet config set --section main rundir /var/run/puppet
in-target /usr/bin/puppet config set --section main factpath /var/lib/puppet/lib/facter
# We currently have an expired root crl in our crl T340543
in-target /usr/bin/puppet config set --section main certificate_revocation leaf
in-target /usr/bin/puppet config set --section agent use_srv_records true
# Send everything to eqiad instead of trying to calculate the correct site
in-target /usr/bin/puppet config set --section agent srv_domain eqiad.wmnet

IFACE=$(ip -4 route list 0/0 | cut -d ' ' -f 5 | head -1)

# Load the qemu module from the guest host. Depending on Debian version, the file can be .ko or .ko.xz
# shellcheck disable=SC2144 # yeah okay `-f` doesn't work with globs but there is only ever one file at a time
if [ -f /target/lib/modules/$(uname -r)/kernel/drivers/firmware/qemu_fw_cfg.ko* ]; then
  cp /target/lib/modules/$(uname -r)/kernel/drivers/firmware/qemu_fw_cfg.ko* /lib/modules/$(uname -r)/kernel/drivers/firmware/
  depmod
  modprobe qemu_fw_cfg
fi

# If a qemu VM:
if [ -f "/sys/firmware/qemu_fw_cfg/by_name/opt/ip6/raw" ]; then
    # Get the v6 from qemu and configure the v6 IP and route.
    IP6=$(cat /sys/firmware/qemu_fw_cfg/by_name/opt/ip6/raw)
    printf '\tup ip addr add %s/128 dev %s\n' "${IP6}" "${IFACE}" >> /target/etc/network/interfaces
    printf '\tup ip route add default via fe80::2022:22ff:fe22:2201 dev %s\n' "${IFACE}" >> /target/etc/network/interfaces
else
    # Configure ipv6 (sorry this is not pretty)
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
fi
