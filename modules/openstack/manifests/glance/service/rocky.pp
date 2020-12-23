class openstack::glance::service::rocky(
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $glance_data_dir,
    $ldap_user_pass,
    $keystone_admin_uri,
    $keystone_public_uri,
    Stdlib::Port $api_bind_port,
    Stdlib::Port $registry_bind_port,
    Array[String] $glance_backends,
    String $ceph_pool,
) {
    require "openstack::serverpackages::rocky::${::lsbdistcodename}"

    package { 'glance':
        ensure => 'present',
    }

    file {
        '/etc/glance/glance-api.conf':
            content   => template('openstack/rocky/glance/glance-api.conf.erb'),
            owner     => 'glance',
            group     => 'nogroup',
            mode      => '0440',
            show_diff => false,
            notify    => Service['glance-api'],
            require   => Package['glance'];
        '/etc/glance/glance-registry.conf':
            content => template('openstack/rocky/glance/glance-registry.conf.erb'),
            owner   => 'glance',
            group   => 'nogroup',
            mode    => '0440',
            notify  => Service['glance-registry'],
            require => Package['glance'];
        '/etc/glance/policy.json':
            ensure  => 'absent';
        '/etc/glance/policy.yaml':
            source  => 'puppet:///modules/openstack/rocky/glance/policy.yaml',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['glance-api'],
            require => Package['glance'];
        '/etc/init.d/glance-api':
            content => template('openstack/rocky/glance/glance-api'),
            owner   => 'root',
            group   => 'root',
            mode    => '0755',
            notify  => Service['glance-api'],
            require => Package['glance'];
    }

    if debian::codename::ge('buster') {
        # The Buster version of the Rocky packages seems to not create the 'glance' service user.
        group { 'glance':
            ensure => 'present',
            name   => 'glance',
            system => true,
        }

        user { 'glance':
            ensure     => 'present',
            name       => 'glance',
            comment    => 'glance system user',
            gid        => 'glance',
            managehome => true,
            require    => Package['glance'],
            system     => true,
        }
    }

    service { 'glance-registry':
        ensure  => true,
        require => Package['glance'],
    }
}
