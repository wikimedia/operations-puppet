#!/bin/sh

set -e
set -x

# Install the public root ssh key
mkdir /target/root/.ssh
wget -O /target/root/.ssh/authorized_keys http://apt.wikimedia.org/autoinstall/ssh/authorized_keys
chmod go-rwx /target/root/.ssh/authorized_keys

# openssh-server: to make the machine accessible
# puppet: because we'll need it soon anyway
# lldpd: announce the machine on the network
apt-install openssh-server puppet lldpd

# Change /etc/motd to read the auto-install date
chroot /target /bin/sh -c 'echo $(cat /etc/issue.net) auto-installed on $(date). > /etc/motd.tail'

# Disable IPv6 privacy extensions before the first boot
[ -f /target/etc/sysctl.d/10-ipv6-privacy.conf ] && rm -f /target/etc/sysctl.d/10-ipv6-privacy.conf

# optimized mkfs for all cache nodes
# (the crazy PHYS_CORES thing is to get the bnx2x option set before the first boot,
#  otherwise we'd need a reboot after puppet sets up the same file on the first run)
case `hostname` in \
	cp[1234]*)
		mount -t sysfs none /target/sys
		PHYS_CORES=$(chroot /target /usr/bin/ruby -e "require 'pathname'; print Pathname::glob('/sys/devices/system/cpu/cpu[0-9]*/topology/thread_siblings_list').map{|x| File.open(x,'r').read().split(',')[0] }.sort.uniq.count")
		umount /target/sys
		chroot /target /bin/sh -c "echo options bnx2x num_queues=$PHYS_CORES >/etc/modprobe.d/rps.conf"
		mke2fs -F -F -t ext4 -T huge -m 0 -L sda3-varnish /dev/sda3
		mke2fs -F -F -t ext4 -T huge -m 0 -L sdb3-varnish /dev/sdb3
		;; \
esac

# Use a more recent kernel on jessie
# (the upgrade is to grab our updated firmware packages first for initramfs)
apt-install lsb-release
if [ "$(chroot /target /usr/bin/lsb_release --codename --short)" = "jessie" ]; then
	in-target apt-get -y upgrade
	apt-install linux-meta-4.9
fi

# Temporarily pre-provision swift user at a fixed UID on new installs.
# Once T123918 is resolved and swift is uid/gid 130 everywhere, this can be
# moved to puppet.
case `hostname` in \
	ms-be[123]*|ms-fe[123]*)
		in-target /usr/sbin/groupadd --gid 130 --system swift
		in-target /usr/sbin/useradd --gid 130 --uid 130 --system --shell /bin/false swift
	;; \
esac
