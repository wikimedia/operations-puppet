class openstack::glance::service::newton(
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $glance_data,
    $ldap_user_pass,
    $keystone_admin_uri,
    $keystone_public_uri,
    Stdlib::Port $api_bind_port,
    Stdlib::Port $registry_bind_port,
) {
    require "openstack::serverpackages::newton::${::lsbdistcodename}"

    package { 'glance':
        ensure => 'present',
    }

    file {
        '/etc/glance/glance-api.conf':
            content => template('openstack/newton/glance/glance-api.conf.erb'),
            owner   => 'glance',
            group   => 'nogroup',
            mode    => '0440',
            notify  => Service['glance-api'],
            require => Package['glance'];
        '/etc/glance/glance-registry.conf':
            content => template('openstack/newton/glance/glance-registry.conf.erb'),
            owner   => 'glance',
            group   => 'nogroup',
            mode    => '0440',
            notify  => Service['glance-registry'],
            require => Package['glance'];
        '/etc/glance/policy.json':
            source  => 'puppet:///modules/openstack/newton/glance/policy.json',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['glance-api'],
            require => Package['glance'];
    }
}
