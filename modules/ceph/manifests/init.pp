# Class: ceph
#
# This class manages the Ceph common packages and configuration
#
# Parameters
#    - $mon_hosts
#        List of monitor FQDN hostnames
#    - $mon_addrs
#        List of monitor IPv4 addresses
#    - $fsid
#        Ceph filesystem ID
class ceph (
    Array[Stdlib::Fqdn]            $mon_hosts,
    Array[Stdlib::IP::Address::V4] $mon_addrs,
    Stdlib::Unixpath               $data_dir,
    String                         $fsid,
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
        home       => $data_dir,
        managehome => false,
        system     => true,
        require    => Group['ceph'],
    }

    # Setup package repos here on in profile

    package { 'ceph-common':
        ensure => present,
    }

    file { '/etc/ceph/ceph.conf':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('ceph/ceph.conf.erb'),
        require => Package['ceph-common'],
    }
}
