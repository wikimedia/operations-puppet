class openstack::cinder::service::rocky(
    $openstack_controllers,
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $keystone_admin_uri,
    $keystone_public_uri,
    String $ceph_pool,
    Stdlib::Port $api_bind_port,
) {
    require "openstack::serverpackages::rocky::${::lsbdistcodename}"

    package { 'cinder-api':
        ensure => 'present',
    }
    package { 'cinder-scheduler':
        ensure => 'present',
    }

    file {
        '/etc/cinder/cinder.conf':
            content   => template('openstack/rocky/cinder/cinder.conf.erb'),
            owner     => 'cinder',
            group     => 'nogroup',
            mode      => '0440',
            show_diff => false,
            notify    => Service['apache2', 'cinder-scheduler', 'nova-api'],
            require   => Package['cinder-api', 'cinder-scheduler'];
        '/etc/cinder/policy.json':
            ensure  => 'absent';
        '/etc/cinder/policy.yaml':
            source  => 'puppet:///modules/openstack/rocky/cinder/policy.yaml',
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            require => Package['cinder-api'];
    }
}
