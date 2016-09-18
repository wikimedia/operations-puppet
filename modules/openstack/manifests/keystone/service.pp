# keystone is the identity service of openstack
# http://docs.openstack.org/developer/keystone/
class openstack::keystone::service($keystoneconfig, $openstack_version=$::openstack::version) {
    include openstack::repo
    include keystone::hooks

    package { 'keystone':
        ensure  => present,
        require => Class['openstack::repo'];
    }
    package { 'python-oath':
        ensure  => present,
    }
    package { 'python-mysql.connector':
        ensure  => present,
    }

    if $keystoneconfig['token_driver'] == 'redis' {
        package { 'python-keystone-redis':
            ensure => present;
        }
    }

    include network::constants
    $prod_networks = $network::constants::production_networks
    $labs_networks = $network::constants::labs_networks

    file {
        '/etc/keystone/keystone.conf':
            content => template("openstack/${openstack_version}/keystone/keystone.conf.erb"),
            owner   => 'keystone',
            group   => 'keystone',
            notify  => Service['keystone'],
            require => Package['keystone'],
            mode    => '0440';
        '/etc/keystone/policy.json':
            source  => "puppet:///modules/openstack/${openstack_version}/keystone/policy.json",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            require => Package['keystone'];
        '/usr/lib/python2.7/dist-packages/keystone/auth/plugins/wmtotp.py':
            source  => "puppet:///modules/openstack/${openstack_version}/keystone/wmtotp.py",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            require => Package['keystone'];
        '/usr/lib/python2.7/dist-packages/keystone/auth/plugins/password_whitelist.py':
            source  => "puppet:///modules/openstack/${openstack_version}/keystone/password_whitelist.py",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            require => Package['keystone'];
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
        monitoring::service { 'keystone-http-35357':
            description   => 'keystone http',
            check_command => 'check_http_on_port!35357',
        }
        monitoring::service { 'keystone-http-5000': # v2 api is limited here
            description   => 'keystone http',
            check_command => 'check_http_on_port!5000',
        }
    } else {
        service { 'keystone':
            ensure  => stopped,
            require => Package['keystone'];
        }
    }
}
