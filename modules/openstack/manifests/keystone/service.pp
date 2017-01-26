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
        '/var/log/keystone':
            ensure => directory,
            owner  => 'keystone',
            group  => 'www-data',
            mode   => '0775';
        '/var/log/keystone/uwsgi':
            ensure => directory,
            owner  => 'www-data',
            group  => 'www-data',
            mode   => '0755';
        '/etc/keystone':
            ensure => directory,
            owner  => 'keystone',
            group  => 'keystone',
            mode   => '0755';
        '/etc/keystone/keystone.conf':
            content => template("openstack/${openstack_version}/keystone/keystone.conf.erb"),
            owner   => 'keystone',
            group   => 'keystone',
            notify  => Service['uwsgi-keystone-admin', 'uwsgi-keystone-public'],
            require => Package['keystone'],
            mode    => '0444';
        '/etc/keystone/policy.json':
            source  => "puppet:///modules/openstack/${openstack_version}/keystone/policy.json",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            notify  => Service['uwsgi-keystone-admin', 'uwsgi-keystone-public'],
            require => Package['keystone'];
        '/etc/keystone/logging.conf':
            source  => "puppet:///modules/openstack/${openstack_version}/keystone/logging.conf",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            notify  => Service['uwsgi-keystone-admin', 'uwsgi-keystone-public'],
            require => Package['keystone'];
        '/usr/lib/python2.7/dist-packages/wmfkeystoneauth':
            source  => "puppet:///modules/openstack/${openstack_version}/keystone/wmfkeystoneauth",
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['uwsgi-keystone-admin', 'uwsgi-keystone-public'],
            recurse => true;
        '/usr/lib/python2.7/dist-packages/wmfkeystoneauth.egg-info':
            source  => "puppet:///modules/openstack/${openstack_version}/keystone/wmfkeystoneauth.egg-info",
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['uwsgi-keystone-admin', 'uwsgi-keystone-public'],
            recurse => true;
        # Disable the keystone process itself; this will be handled
        #  by nginx and uwsgi
        '/etc/init/keystone.conf':
            ensure  => 'absent';
        '/etc/logrotate.d/keystone-public-uwsgi':
            ensure => present,
            source => 'puppet:///modules/openstack/keystone-public-uwsgi.logrotate',
            owner  => 'root',
            group  => 'root',
            mode   => '0444';
        '/etc/logrotate.d/keystone-admin-uwsgi':
            ensure => present,
            source => 'puppet:///modules/openstack/keystone-admin-uwsgi.logrotate',
            owner  => 'root',
            group  => 'root',
            mode   => '0444';
    }

    if $::fqdn == hiera('labs_nova_controller') {
        # Set up uwsgi services

        # Keystone admin API
        service::uwsgi { 'keystone-admin':
            port            => $keystoneconfig['auth_port'],
            healthcheck_url => '/',
            deployment      => None,
            config          => {
                wsgi-file => '/usr/bin/keystone-wsgi-admin',
                name      => 'keystone',
                processes => '20',
                threads   => '2',
                logto     => '/var/log/keystone/uwsgi/keystone-admin.log',
                logger    => 'file:/var/log/keystone/uwsgi/keystone-admin-uwsgi.log',
            },
        }
        service::uwsgi { 'keystone-public':
            port            => $keystoneconfig['public_port'],
            healthcheck_url => '/',
            deployment      => None,
            config          => {
                wsgi-file => '/usr/bin/keystone-wsgi-public',
                name      => 'keystone',
                processes => '20',
                threads   => '2',
                logto     => '/var/log/keystone/uwsgi/keystone-public.log',
                logger    => 'file:/var/log/keystone/uwsgi/keystone-public-uwsgi.log',
            },
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

        monitoring::service { 'keystone-http-35357':
            description   => 'keystone http',
            check_command => 'check_http_on_port!35357',
        }
        monitoring::service { 'keystone-http-5000': # v2 api is limited here
            description   => 'keystone http',
            check_command => 'check_http_on_port!5000',
        }
    } else {
        # Don't run uwsgi services on the spare
        service { 'uwsgi-keystone-admin':
            ensure => stopped,
        }
        service { 'uwsgi-keystone-public':
            ensure => stopped,
        }
    }

    # stop the keystone process itself; this will be handled
    #  by nginx and uwsgi
    service { 'keystone':
        ensure  => stopped,
        require => Package['keystone'];
    }
}
