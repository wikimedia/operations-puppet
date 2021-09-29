class openstack::manila::service (
    Boolean $enabled,
    String  $version,
) {
    require "openstack::serverpackages::${version}::${::lsbdistcodename}"
    require openstack::manila::configuration

    require_package([
      'manila-api',
      'manila-data',
      'manila-scheduler',
      'python3-manilaclient',
    ])

    service { 'manila-api':
        ensure    => $enabled,
        require   => Package['manila-api'],
        subscribe => File['/etc/manila/manila.conf'],
    }

    service { 'manila-data':
        ensure    => $enabled,
        require   => Package['manila-data'],
        subscribe => File['/etc/manila/manila.conf'],
    }

    service { 'manila-scheduler':
        ensure    => $enabled,
        require   => Package['manila-scheduler'],
        subscribe => File['/etc/manila/manila.conf'],
    }
}
