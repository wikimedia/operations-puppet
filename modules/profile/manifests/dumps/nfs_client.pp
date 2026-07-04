# SPDX-License-Identifier: Apache-2.0
# == Class profile::dumps::nfs_client
#
# Mounts dumps read-only over NFS
#
# Parameters:
#   $ensure: Whether the mount and associated resources should be present (default: 'present').
#   $server: The NFS server hostname to mount (default: 'dumps-nfs.wikimedia.org').
#
class profile::dumps::nfs_client (
    Wmflib::Ensure $ensure = lookup('profile::dumps::nfs_client::ensure', {default_value => present }),
    Stdlib::Host   $server = lookup('profile::dumps::nfs_client::server', {default_value => 'dumps-nfs.wikimedia.org' }),
) {
    ensure_packages(['nfs-common'])

    if !defined(File['/mnt/nfs']) {
      file { '/mnt/nfs':
        ensure => directory,
      }
    }

    # TODO deploy 'dumpsgen' (uid/gid 400) to both cloudvps and prod
    file { '/mnt/nfs/dumps':
      ensure => present,
      owner  => 400,
      group  => 400,
      force  => true,
    }

    # lookupcache=all: trust the attribute/cache lookup results unconditionally; avoids extra stat round-trips on read-only mounts
    # nofsc: disable NFSv4 state management (locks, delegations, open state); appropriate for read-only, no-contention workloads
    $nfs_options = ['ro', 'bg', 'soft', 'tcp', 'noatime', 'lookupcache=all', 'nofsc']
    $retry_options = ['timeo=20', 'retrans=1']
    $systemd_options = ['x-systemd.automount', 'x-systemd.idle-timeout=60', 'x-systemd.mount-timeout=3']
    # nofail: don't fail boot if the NFS server is unreachable
    # _netdev: delay mounting until the network is available
    $network_options = ['nofail', '_netdev']

    mount { '/mnt/nfs/dumps':
      ensure  => $ensure,
      device  => "${server}:/",
      fstype  => 'nfs',
      options => join([$nfs_options, $retry_options, $systemd_options, $network_options], ','),
      atboot  => true,
      require => File['/mnt/nfs/'],
    }

    service { 'mnt-nfs-dumps.automount':
      ensure => stdlib::ensure($ensure, 'service'),
    }

    # The sitter checks the mountpoint for ESTALE errors, and issues umount -l
    file { '/usr/local/bin/dumps-nfs-client-sitter':
      ensure => stdlib::ensure($ensure, 'file'),
      mode   => '0755',
      source => 'puppet:///modules/profile/dumps/nfs_client/sitter.py',
    }

    systemd::service { 'dumps-nfs-client-sitter':
      ensure    => $ensure,
      content   => template('profile/dumps/nfs_client/sitter.service.erb'),
      require   => File['/usr/local/bin/dumps-nfs-client-sitter'],
      subscribe => File['/usr/local/bin/dumps-nfs-client-sitter'],
    }
}
