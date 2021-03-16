# Class: ceph::common
#
# This class configures the host for the ceph-common package.
#
# Parameters
#    - $home_dir
#        The ceph user home directory (usually the top level data directory)
#
class ceph::common (
    Stdlib::Unixpath $home_dir,
) {
    group { 'ceph':
        ensure => present,
        system => true,
    }

    user { 'ceph':
        ensure     => present,
        gid        => 'ceph',
        shell      => '/usr/sbin/nologin',
        comment    => 'Ceph storage service',
        home       => $home_dir,
        managehome => false,
        system     => true,
        require    => Group['ceph'],
    }

    # Ceph common package used for all services and clients
    package { 'ceph-common':
        ensure  => present,
        require => User['ceph'],
    }

    # fio is used for performance tests and debugging
    ensure_packages(['fio'])

    file { '/var/lib/ceph':
        ensure => directory,
        mode   => '0750',
        owner  => 'ceph',
        group  => 'ceph',
    }

    file { '/var/log/ceph':
        ensure => directory,
        mode   => '0755',
        owner  => 'ceph',
        group  => 'ceph',
    }

    file { '/var/run/ceph':
        ensure => directory,
        mode   => '0750',
        owner  => 'ceph',
        group  => 'ceph',
    }
}
