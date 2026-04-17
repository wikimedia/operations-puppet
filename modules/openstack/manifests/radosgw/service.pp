class openstack::radosgw::service(
    String              $version,
) {
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
