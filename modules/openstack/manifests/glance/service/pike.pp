class openstack::glance::service::pike(
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
    require "openstack::serverpackages::pike::${::lsbdistcodename}"

    package { 'glance':
        ensure => 'present',
    }

    file {
        '/etc/glance/glance-api.conf':
            content   => template('openstack/pike/glance/glance-api.conf.erb'),
            owner     => 'glance',
            group     => 'nogroup',
            mode      => '0440',
            show_diff => false,
            notify    => Service['glance-api'],
            require   => Package['glance'];
        '/etc/glance/glance-registry.conf':
            content => template('openstack/pike/glance/glance-registry.conf.erb'),
            owner   => 'glance',
            group   => 'nogroup',
            mode    => '0440',
            notify  => Service['glance-registry'],
            require => Package['glance'];
        '/etc/glance/policy.json':
            source  => 'puppet:///modules/openstack/pike/glance/policy.json',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['glance-api'],
            require => Package['glance'];
    }
}
