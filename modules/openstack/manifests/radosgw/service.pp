class openstack::radosgw::service(
    String              $version,
) {
    require "openstack::serverpackages::${version}::${::lsbdistcodename}"

    package { ['radosgw']:
        ensure => 'present',
    }

    service { 'ceph-radosgw@radosgw':
        ensure    => 'running',
        require   => Package['radosgw'],
        enable    => true,
        subscribe => File['/etc/ceph/ceph.conf'],
    }
}
