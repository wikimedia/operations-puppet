class openstack::glance::service::mitaka(
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $glance_data,
    $ldap_user_pass,
    $keystone_admin_uri,
    $keystone_public_uri,
) {
    require "openstack::serverpackages::mitaka::${::lsbdistcodename}"

    package { 'glance':
        ensure => 'present',
    }

    file {
        '/etc/glance/glance-api.conf':
            content => template('openstack/mitaka/glance/glance-api.conf.erb'),
            owner   => 'glance',
            group   => 'nogroup',
            mode    => '0440',
            notify  => Service['glance-api'],
            require => Package['glance'];
        '/etc/glance/glance-registry.conf':
            content => template('openstack/mitaka/glance/glance-registry.conf.erb'),
            owner   => 'glance',
            group   => 'nogroup',
            mode    => '0440',
            notify  => Service['glance-registry'],
            require => Package['glance'];
        '/etc/glance/policy.json':
            source  => 'puppet:///modules/openstack/mitaka/glance/policy.json',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['glance-api'],
            require => Package['glance'];
    }
}
