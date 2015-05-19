class openstack::keystone::service($openstack_version=$::openstack::version, $keystoneconfig, $glanceconfig) {
    include openstack::repo

    package { [ "keystone" ]:
        ensure  => present,
        require => Class["openstack::repo"];
    }

    if $keystoneconfig['token_driver'] == 'redis' {
        package { [ "python-keystone-redis" ]:
            ensure => present;
        }
    }

    service { "keystone":
        ensure    => running,
        subscribe => File['/etc/keystone/keystone.conf'],
        require   => Package["keystone"];
    }

    file {
        "/etc/keystone/keystone.conf":
            content => template("openstack/${openstack_version}/keystone/keystone.conf.erb"),
            owner   => keystone,
            group   => keystone,
            notify  => Service["keystone"],
            require => Package["keystone"],
            mode    => '0440';
    }

    # Clean up expired keystone tokens, because keystone seems to leak them
    $keystone_db_name = $keystoneconfig['db_name']
    $keystone_db_user = $keystoneconfig['db_user']
    $keystone_db_pass = $keystoneconfig['db_pass']
    $keystone_db_host = $keystoneconfig['db_host']
    cron {
        'cleanup_expired_keystone_tokens':
            user    => 'root',
            minute  => 20,
            ensure  => present,
            command => "/usr/bin/mysql $keystone_db_name -h${keystone_db_host} -u${keystone_db_user} -p${keystone_db_pass} -e 'DELETE FROM token WHERE NOW() - INTERVAL 2 day > expires LIMIT 10000;'",
    }
}
