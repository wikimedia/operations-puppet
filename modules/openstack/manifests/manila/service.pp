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
        ensure  => $enabled,
        require => Package['manila-api'],
    }

    service { 'manila-data':
        ensure  => $enabled,
        require => Package['manila-data'],
    }

    service { 'manila-scheduler':
        ensure  => $enabled,
        require => Package['manila-scheduler'],
    }
}
