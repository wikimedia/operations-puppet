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
# lsb-release: allows conditionals in this script on in-target release codename
apt-install openssh-server puppet lldpd lsb-release

# nvme-cli: on machines with NVMe drives, this allows late_command to change
# LBA format below, but this package doesn't exist in jessie
if [ "$(chroot /target /usr/bin/lsb_release --codename --short)" != "jessie" ]; then
	apt-install nvme-cli
fi

# Change /etc/motd to read the auto-install date
chroot /target /bin/sh -c 'echo $(cat /etc/issue.net) auto-installed on $(date). > /etc/motd.tail'

# Disable IPv6 privacy extensions before the first boot
[ -f /target/etc/sysctl.d/10-ipv6-privacy.conf ] && rm -f /target/etc/sysctl.d/10-ipv6-privacy.conf

# cpNNNN mkfs options are tweaked for our use-case with the whole FS filled by
# a single-digit count of files and no need for extra integrity in case of
# drive failure, no journalling, no extra fs features.  bigalloc with 16k
# cluster size maximizes available space for a single file on the newest
# drives, and is close enough to optimal on the older ones.
cp_mke2fs_args="-F -F -t ext4 -O bigalloc,sparse_super2,^resize_inode,^has_journal,^ext_attr,^extra_isize,^dir_nlink,^dir_index,^filetype -b 4096 -N 16 -I 128 -C 16k -E num_backup_sb=0,packed_meta_blocks=1 -m 0"

case `hostname` in \
	cp107[5-9]|cp108[0-9]|cp1090)
		# new cache nodes (mid-2018) use a single NVMe drive (Samsung
		# pm1725a) for storage, which needs its LBA format changed to
		# 4K block size before manually partitioning and formatting.
		in-target /usr/sbin/nvme format /dev/nvme0n1 -l 2
		echo ';' | /usr/sbin/sfdisk /dev/nvme0n1
		/sbin/mke2fs ${cp_mke2fs_args} -L cache-store /dev/nvme0n1p1
		;; \
	cp[1-9]*)
		# older cache node storage are all partitioned by partman to
		# match this numbering and we just need to do the 2x mkfs
		/sbin/mke2fs ${cp_mke2fs_args} -L sda3-varnish /dev/sda3
		/sbin/mke2fs ${cp_mke2fs_args} -L sdb3-varnish /dev/sdb3
		;; \
esac

# Use a more recent kernel on jessie and deinstall nfs-common/rpcbind
# (we don't want these to be installed in general, only pull them in
# where actually needed. >= stretch doesn't install nfs-common/rpcbind
# any longer (T106477)
# (the upgrade is to grab our updated firmware packages first for initramfs)
if [ "$(chroot /target /usr/bin/lsb_release --codename --short)" = "jessie" ]; then
	in-target apt-get -y upgrade
	apt-install linux-meta-4.9
	in-target dpkg --purge rpcbind nfs-common libnfsidmap2 libtirpc1
fi

# On buster we need facter 2 for the initial puppet run. facter 2.4.6-1+deb10u1
# is built for buster-wikimedia/main (at some point we'll switch to facter 3 fleet-wide,
# then we can drop this)
if [ "$(chroot /target /usr/bin/lsb_release --codename --short)" = "buster" ]; then
	in-target apt-get -y install facter=2.4.6-1+deb10u1
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
