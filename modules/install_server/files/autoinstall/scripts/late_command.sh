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
# nvme-cli: on machines with NVMe drives, this allows late_command to change LBA format
apt-install openssh-server puppet lldpd nvme-cli

# Change /etc/motd to read the auto-install date
chroot /target /bin/sh -c 'echo $(cat /etc/issue.net) auto-installed on $(date). > /etc/motd.tail'

# Disable IPv6 privacy extensions before the first boot
[ -f /target/etc/sysctl.d/10-ipv6-privacy.conf ] && rm -f /target/etc/sysctl.d/10-ipv6-privacy.conf

case `hostname` in \
	cp107[5-9]|cp108[0-9]|cp1090)
		# new cache nodes (mid-2018) use a single nvme drive (Samsung
		# pm1725a) for storage, which needs its LBA format changed to
		# 4K block size before manually partitioning and formatting.
		# mkfs options are tweaked for our use-case with the whole FS
		# filled by a single-digit count of files and no need for extra
		# integrity in case of drive failure, and no journalling
		in-target /usr/sbin/nvme format /dev/nvme0n1 -l 2
		echo ';' | /usr/sbin/sfdisk /dev/nvme0n1
		/sbin/mke2fs -F -F -t ext4 -O bigalloc,sparse_super2,^has_journal,^ext_attr,^dir_nlink,^dir_index,^extra_isize -b 4096 -C 16M -N 16 -I 128 -E num_backup_sb=0,packed_meta_blocks=1 -m 0 -L cache-store /dev/nvme0n1p1
		;; \
	cp[1-9]*)
		# older cache node storage are all partitioned by partman to
		# match this numbering and we just need to do the 2x mkfs
		/sbin/mke2fs -F -F -t ext4 -T huge -m 0 -L sda3-varnish /dev/sda3
		/sbin/mke2fs -F -F -t ext4 -T huge -m 0 -L sdb3-varnish /dev/sdb3
		;; \
esac

# Use a more recent kernel on jessie and deinstall nfs-common/rpcbind
# (we don't want these to be installed in general, only pull them in
# where actually needed. stretch doesn't install nfs-common/rpcbind
# any longer (T106477)
# (the upgrade is to grab our updated firmware packages first for initramfs)
apt-install lsb-release
if [ "$(chroot /target /usr/bin/lsb_release --codename --short)" = "jessie" ]; then
	in-target apt-get -y upgrade
	apt-install linux-meta-4.9
	in-target dpkg --purge rpcbind nfs-common libnfsidmap2 libtirpc1
fi

# Temporarily pre-provision swift user at a fixed UID on new installs.
# Once T123918 is resolved and swift is uid/gid 130 everywhere, this can be
# moved to puppet.
case `hostname` in \
	ms-be[123]*|ms-fe[123]*)
		in-target /usr/sbin/groupadd --gid 130 --system swift
		in-target /usr/sbin/useradd --gid 130 --uid 130 --system --shell /bin/false \
			--create-home --home /var/lib/swift swift
	;; \
esac

# Enable structured puppet facts on first puppet run, same as production - T169612
in-target /usr/bin/puppet config set --section agent stringify_facts false
