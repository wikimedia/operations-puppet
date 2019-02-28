class profile::mediawiki::php::monitoring(
    $prometheus_nodes = hiera('prometheus_nodes'),
    $auth_passwd = hiera('profile::mediawiki::php::monitoring::password'),
    $auth_salt = hiera('profile::mediawiki::php::monitoring::salt'),
    Optional[Wmflib::UserIpPort] $fcgi_port = hiera('profile::php_fpm::fcgi_port', undef),
    String $fcgi_pool = hiera('profile::mediawiki::fcgi_pool', 'www'),
    Boolean $monitor_page = hiera('profile::mediawiki::php::monitoring::monitor_page', true),
) {
    require ::network::constants
    require ::profile::mediawiki::php
    $fcgi_proxy = mediawiki::fcgi_endpoint($fcgi_port, $fcgi_pool)
    $admin_port = 9181
    $docroot = '/var/www/php-monitoring'
    $htpasswd_file = '/etc/apache2/htpasswd.php7adm'
    $prometheus_nodes_str = join($prometheus_nodes, ' ')
    $deployment_nodes = $::network::constants::special_hosts[$::realm]['deployment_hosts']
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
        }
    }
    else {
        # Check that the basic health check url can be rendered via php-fpm.
        monitoring::service { 'appserver_health_php7':
            description    => 'PHP7 rendering',
            check_command  => 'check_http_jobrunner_php7',
            retries        => 2,
            retry_interval => 2,
        }
    }
    # TODO: add an else with a check for /w/health-check.php
}
