class openstack::radosgw::service(
    String              $version,
) {
    require "openstack::serverpackages::${version}::${::lsbdistcodename}"

    package { ['radosgw']:
        ensure => 'present',
    }

    service { "ceph-radosgw@rgw.${::hostname}":
        require => Package['radosgw'],
    }
}
