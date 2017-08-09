# keystone is the identity service of openstack
# http://docs.openstack.org/developer/keystone/

class openstack2::keystone::service(
    $version,
    $nova_controller,
    $osm_host,
    $db_name,
    $db_user,
    $db_pass,
    $db_host,
    $token_driver,
    $ldap_hosts,
    $ldap_base_dn,
    $ldap_user_id_attribute,
    $ldap_user_name_attribute,
    $ldap_user_dn,
    $ldap_user_pass,
    $auth_protocol,
    $auth_port,
    $wiki_status_page_prefix,
    $wiki_status_consumer_token,
    $wiki_status_consumer_secret,
    $wiki_status_access_token,
    $wiki_status_access_secret,
    $wiki_consumer_token,
    $wiki_consumer_secret,
    $wiki_access_token,
    $wiki_access_secret,
    ) {

    #include ::openstack::keystone::hooks
    include ::network::constants
    $prod_networks = $network::constants::production_networks
    $labs_networks = $network::constants::labs_networks

    package { 'keystone':
        ensure  => present,
    }
    package { 'python-oath':
        ensure  => present,
    }
    package { 'python-mysql.connector':
        ensure  => present,
    }

    if $token_driver == 'redis' {
        package { 'python-keystone-redis':
            ensure => present;
        }
    }

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
            content => template("openstack2/${version}/keystone/keystone.conf.erb"),
            owner   => 'keystone',
            group   => 'keystone',
            notify  => Service['uwsgi-keystone-admin', 'uwsgi-keystone-public'],
            require => Package['keystone'],
            mode    => '0444';
        '/etc/keystone/keystone-paste.ini':
            source  => "puppet:///modules/openstack2/${version}/keystone/keystone-paste.ini",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            notify  => Service['uwsgi-keystone-admin', 'uwsgi-keystone-public'],
            require => Package['keystone'];
        '/etc/keystone/policy.json':
            source  => "puppet:///modules/openstack2/${version}/keystone/policy.json",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            notify  => Service['uwsgi-keystone-admin', 'uwsgi-keystone-public'],
            require => Package['keystone'];
        '/etc/keystone/logging.conf':
            source  => "puppet:///modules/openstack2/${version}/keystone/logging.conf",
            mode    => '0644',
            owner   => 'root',
            group   => 'root',
            notify  => Service['uwsgi-keystone-admin', 'uwsgi-keystone-public'],
            require => Package['keystone'];
        '/usr/lib/python2.7/dist-packages/wmfkeystoneauth':
            source  => "puppet:///modules/openstack2/${version}/keystone/wmfkeystoneauth",
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['uwsgi-keystone-admin', 'uwsgi-keystone-public'],
            recurse => true;
        '/usr/lib/python2.7/dist-packages/wmfkeystoneauth.egg-info':
            source  => "puppet:///modules/openstack2/${version}/keystone/wmfkeystoneauth.egg-info",
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            notify  => Service['uwsgi-keystone-admin', 'uwsgi-keystone-public'],
            recurse => true;
    }

    logrotate::conf { 'keystone-public-uwsgi':
        ensure => present,
        source => 'puppet:///modules/openstack2/keystone-public-uwsgi.logrotate',
    }

    logrotate::conf { 'keystone-admin-uwsgi':
        ensure => present,
        source => 'puppet:///modules/openstack2/keystone-admin-uwsgi.logrotate',
    }

    if $::fqdn == $nova_controller {
        # Clean up expired keystone tokens, because otherwise keystone leaves them
        #  around forever.
        cron {
            'cleanup_expired_keystone_tokens':
                ensure  => present,
                user    => 'root',
                minute  => 20,
                command => '/usr/bin/keystone-manage token_flush > /dev/null 2>&1',
        }

        # Clean up service user tokens.  These tend to pile up
        #  quickly, and are never used for Horizon sessions.
        #  so, don't wait for them to expire, just delete them
        #  after a few hours.
        #
        # Tokens only know when they expire and not when they
        #  were created.  Since token lifespan is 7.1
        #  days (613440 seconds), any token that expires
        #  less than 7 days from now is already at least
        #  2 hours old.

        cron {
            'cleanup_novaobserver_keystone_tokens':
                ensure  => present,
                user    => 'root',
                minute  => 30,
                command => "/usr/bin/mysql ${db_name} -h${db_host} -u${db_user} -p${db_pass} -e 'DELETE FROM token WHERE user_id=\"novaobserver\" AND NOW() + INTERVAL 7 day > expires LIMIT 10000;'",
        }
        cron {
            'cleanup_novaadmin_keystone_tokens':
                ensure  => present,
                user    => 'root',
                minute  => 40,
                command => "/usr/bin/mysql ${db_name} -h${db_host} -u${db_user} -p${db_pass} -e 'DELETE FROM token WHERE user_id=\"novaadmin\" AND NOW() + INTERVAL 7 day > expires LIMIT 10000;'",
        }

        monitoring::service { 'keystone-http-35357':
            description   => 'keystone admin endpoint',
            check_command => 'check_http_on_port!35357',
        }

        monitoring::service { 'keystone-http-5000': # v2 api is limited here
            description   => 'keystone public endoint',
            check_command => 'check_http_on_port!5000',
        }

        if ($version == 'liberty') {
            # Keystone says that you should run it with uwsgi in Liberty,
            #  but it's actually buggy and terrible in that config.  So, use eventlet
            #  ('keystone' service) on liberty, and we'll try uwsgi again on mitaka.
            $enable_uwsgi = false

            service { 'keystone':
                ensure    => running,
                subscribe => File['/etc/keystone/keystone.conf'],
                require   => Package['keystone'];
            }
            service { 'uwsgi-keystone-admin':
                ensure => stopped,
            }
            service { 'uwsgi-keystone-public':
                ensure => stopped,
            }
        } else {
            $enable_uwsgi = true

            # stop the keystone process itself; this will be handled
            #  by uwsgi
            service { 'keystone':
                ensure  => stopped,
                require => Package['keystone'];
            }
            file {'/etc/init/keystone.conf':
                ensure  => 'absent';
            }
        }
    } else {
        $enable_uwsgi = false

        # Because of the enabled => false, the uwsgi::app
        #  declarations below don't actually define
        #  services for the keystone processes.  We need
        #  to define them here (even though they're stopped)
        #  so we can refer to them elsewhere.
        service { 'uwsgi-keystone-admin':
            ensure => stopped,
        }
        service { 'uwsgi-keystone-public':
            ensure => stopped,
        }
        service { 'keystone':
            ensure  => stopped,
            require => Package['keystone'];
        }
    }

    # Set up uwsgi services

    # Keystone admin API
    uwsgi::app { 'keystone-admin':
        enabled  => $enable_uwsgi,
        settings => {
            uwsgi => {
                die-on-term => true,
                http        => "0.0.0.0:${auth_port}",
                logger      => 'file:/var/log/keystone/uwsgi/keystone-admin-uwsgi.log',
                master      => true,
                name        => 'keystone',
                plugins     => 'python, python3, logfile',
                processes   => '20',
                wsgi-file   => '/usr/bin/keystone-wsgi-admin',
            },
        },
    }
    uwsgi::app { 'keystone-public':
        enabled  => $enable_uwsgi,
        settings => {
            uwsgi => {
                die-on-term => true,
                http        => '0.0.0.0:5000',
                logger      => 'file:/var/log/keystone/uwsgi/keystone-public-uwsgi.log',
                master      => true,
                name        => 'keystone',
                plugins     => 'python, python3, logfile',
                processes   => '20',
                wsgi-file   => '/usr/bin/keystone-wsgi-public',
            },
        },
    }
}
