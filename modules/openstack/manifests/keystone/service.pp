class openstack::keystone::service($openstack_version=$::openstack::version, $keystoneconfig, $glanceconfig) {
    include openstack::repo

    package { [ 'keystone' ]:
        ensure  => present,
        require => Class['openstack::repo'];
    }

    if $keystoneconfig['token_driver'] == 'redis' {
        package { [ 'python-keystone-redis' ]:
            ensure => present;
        }
    }


    service { 'keystone':
        ensure    => running,
        subscribe => File['/etc/keystone/keystone.conf'],
        require   => Package['keystone'];
    }

    file {
        '/etc/keystone/keystone.conf':
            content => template("openstack/${openstack_version}/keystone/keystone.conf.erb"),
            owner   => keystone,
            group   => keystone,
            notify  => Service['keystone'],
            require => Package['keystone'],
            mode    => '0440';
    }
}
