class profile::mediawiki::php::monitoring(
    Array[Stdlib::Host] $prometheus_nodes = lookup('prometheus_nodes'),
    String $auth_passwd = lookup('profile::mediawiki::php::monitoring::password'),
    String $auth_salt = lookup('profile::mediawiki::php::monitoring::salt'),
    Optional[Stdlib::Port::User] $fcgi_port = lookup('profile::php_fpm::fcgi_port', {default_value => undef}),
    String $fcgi_pool = lookup('profile::mediawiki::fcgi_pool', {default_value => 'www'}),
    Boolean $monitor_page = lookup('profile::mediawiki::php::monitoring::monitor_page', {default_value => true}),
    Array[String] $deployment_nodes = lookup('deployment_hosts', {default_value => []}),
    Boolean $monitor_opcache = lookup('profile::mediawiki::php::monitoring::monitor_opcache', {default_value => true}),
) {
    require ::network::constants
    require ::profile::mediawiki::php
    $fcgi_proxy = mediawiki::fcgi_endpoint($fcgi_port, $fcgi_pool)
    $admin_port = 9181
    $docroot = '/var/www/php-monitoring'
    $htpasswd_file = '/etc/apache2/htpasswd.php7adm'
    $prometheus_nodes_str = join($prometheus_nodes, ' ')
    # Admin interface (and prometheus metrics) for APCu and opcache
    file { $docroot:
        ensure  => directory,
        recurse => true,
        owner   => 'root',
        group   => 'www-data',
        mode    => '0555',
        source  => 'puppet:///modules/profile/mediawiki/php/admin'
    }
    httpd::conf { 'php-admin-port':
        ensure  => present,
        content => "# This file is managed by puppet\nListen ${admin_port}\n"
    }
    httpd::site { 'php-admin':
        ensure  => present,
        content => template('profile/mediawiki/php-admin.conf.erb')
    }

    $htpasswd_string = htpasswd($auth_passwd, $auth_salt)
    file { $htpasswd_file:
        ensure  => present,
        content => "root:${htpasswd_string}\n",
        owner   => 'root',
        group   => 'www-data',
        mode    => '0440'
    }

    # Needed to allow scap to perform opcache invalidation.
    ferm::service { 'phpadmin_deployment':
        ensure => present,
        proto  => 'tcp',
        port   => $admin_port,
        srange => '$DEPLOYMENT_HOSTS',
    }

    $ferm_srange = "(@resolve((${prometheus_nodes_str})) @resolve((${prometheus_nodes_str}), AAAA))"
    ferm::service { 'prometheus-php-cache-exporter':
        proto  => 'tcp',
        port   => $admin_port,
        srange => $ferm_srange,
    }

    ## Admin script
    file { '/usr/local/bin/php7adm':
        ensure => present,
        source => 'puppet:///modules/profile/mediawiki/php/php7adm.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    file { '/etc/php7adm.netrc':
        ensure  => present,
        content => "machine localhost login root password ${auth_passwd}\n",
        owner   => 'root',
        group   => 'ops',
        mode    => '0440',
    }
    ## Monitoring
    # Check that php-fpm is running
    $svc_name = "php${profile::mediawiki::php::php_version}-fpm"
    nrpe::monitor_systemd_unit_state{ $svc_name: }
    # Export basic php-fpm stats using a textfile exporter
    class { '::prometheus::node_phpfpm_statustext':
        service => "${svc_name}.service",
    }

    if $monitor_page {
        # Check that a simple page can be rendered via php-fpm.
        # If a service check happens to run while we are performing a
        # graceful restart of Apache, we want to try again before declaring
        # defeat.
        monitoring::service { 'appserver_http_php7':
            description    => 'PHP7 rendering',
            check_command  => 'check_http_wikipedia_main_php7',
            retries        => 2,
            retry_interval => 2,
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Application_servers/Runbook#PHP7_rendering',
        }
    }
    else {
        # Check that the basic health check url can be rendered via php-fpm.
        monitoring::service { 'appserver_health_php7':
            description    => 'PHP7 rendering',
            check_command  => 'check_http_jobrunner_php7',
            retries        => 2,
            retry_interval => 2,
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Application_servers/Runbook#PHP7_rendering',
        }
    }
    # Monitor opcache status
    file { '/usr/local/lib/nagios/plugins/nrpe_check_opcache':
        ensure => present,
        source => 'puppet:///modules/profile/mediawiki/php/nrpe_check_opcache.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    if $monitor_opcache {
        nrpe::monitor_service { 'opcache':
            description  => 'PHP opcache health',
            nrpe_command => '/usr/local/lib/nagios/plugins/nrpe_check_opcache -w 100 -c 50',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Application_servers/Runbook#PHP7_opcache_health',
        }
    }
}
