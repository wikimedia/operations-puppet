# keystone is the identity service of openstack
# http://docs.openstack.org/developer/keystone/
class openstack::keystone::service($openstack_version=$::openstack::version, $keystoneconfig) {
    include openstack::repo

    package { 'keystone':
        ensure  => present,
        require => Class['openstack::repo'];
    }

    if $keystoneconfig['token_driver'] == 'redis' {
        package { 'python-keystone-redis':
            ensure => present;
        }
    }

    file {
        '/etc/keystone/keystone.conf':
            content => template("openstack/${openstack_version}/keystone/keystone.conf.erb"),
            owner   => keystone,
            group   => keystone,
            notify  => Service['keystone'],
            require => Package['keystone'],
            mode    => '0440';
        '/etc/keystone/policy.json':
            source  => "puppet:///modules/openstack/${openstack_version}/keystone/policy.json",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            require => Package['keystone'];
        '/etc/keystone/domains/':
            ensure  => directory,
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            require => Package['keystone'];
        '/etc/keystone/domains/keystone.Default.conf':
            source  => "puppet:///modules/openstack/${openstack_version}/keystone/domains/keystone.Default.conf.erb",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            require => File['/etc/keystone/domains/'];
    }

    if $::fqdn == hiera('labs_nova_controller') {
        service { 'keystone':
            ensure    => running,
            subscribe => File['/etc/keystone/keystone.conf'],
            require   => Package['keystone'];
        }

        # Clean up expired keystone tokens, because keystone seems to leak them
        $keystone_db_name = $keystoneconfig['db_name']
        $keystone_db_user = $keystoneconfig['db_user']
        $keystone_db_pass = $keystoneconfig['db_pass']
        $keystone_db_host = $keystoneconfig['db_host']
        cron {
            'cleanup_expired_keystone_tokens':
                ensure  => present,
                user    => 'root',
                minute  => 20,
                command => "/usr/bin/mysql ${keystone_db_name} -h${keystone_db_host} -u${keystone_db_user} -p${keystone_db_pass} -e 'DELETE FROM token WHERE NOW() - INTERVAL 2 day > expires LIMIT 10000;'",
        }

        nrpe::monitor_service { 'check_keystone_process':
            description  => 'keystone process',
            nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array '^/usr/bin/python /usr/bin/keystone-all'",
        }
    } else {
        service { 'keystone':
            ensure    => stopped,
            require   => Package['keystone'];
        }
    }
}
