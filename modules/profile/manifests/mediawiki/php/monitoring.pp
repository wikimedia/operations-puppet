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
    $php_versions = $profile::mediawiki::php::php_versions
    $versioned_port = php::fpm::versioned_port($fcgi_port, $php_versions)
    $default_php_version = $php_versions[0]
    $admin_port = 9181
    $admin_data = $php_versions.map |$idx, $php_version| {
        $versioned_fcgi_pool = $php_version ? {
            $default_php_version => $fcgi_pool,
            default              => "${fcgi_pool}-${php_version}"
        }
        $versioned_admin_port = $admin_port + $idx
        $retval = {
            'version'    => $php_version,
            'fcgi_proxy' => mediawiki::fcgi_endpoint($versioned_port[$php_version], $versioned_fcgi_pool),
            'admin_port' => $versioned_admin_port
        }
    }

    $docroot = '/var/www/php-monitoring'
    $htpasswd_file = '/etc/apache2/htpasswd.php7adm'
    # used in php-admin.conf.erb
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
        content => template('profile/mediawiki/php-admin-ports.conf.erb')
    }
    # Will actually be one virtualhost per php version.
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

    # TODO: remove this. It was added to allow opcache invalidation from scap but we're definitely
    # not doing it now. Also remove it from the virtualhosts.
    ferm::service { 'phpadmin_deployment':
        ensure => present,
        proto  => 'tcp',
        port   => $admin_port,
        srange => '$DEPLOYMENT_HOSTS',
    }

    ## Admin script
    file { '/usr/local/bin/php7adm':
        ensure => present,
        source => 'puppet:///modules/profile/mediawiki/php/php7adm.sh',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
    # Create a hash of php_version => admin port, save it as json in a file.
    $version_ports = $admin_data.map |$d| {
        {$d['version'] => $d['admin_port']}
    }.reduce({}) |$m,$v| {$m.merge($v)}
    file { '/etc/php7adm.versions':
        ensure  => present,
        content => $version_ports.to_json,
        owner   => 'root',
        group   => 'ops',
        mode    => '0444',
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
    $php_versions.each |$php_version| {
        $svc_name = php::fpm::programname($php_version)
        nrpe::monitor_systemd_unit_state{ $svc_name: }
    }

    # Export basic php-fpm stats using a textfile exporter
    class { '::prometheus::node_phpfpm_statustext':
        php_versions => $php_versions,
    }
    # TODO: extend all this beyond the default php version that is assumed here.
    # It will be done once we've moved to serving actual traffic with more than one version of
    # php.
    if $monitor_page {
        # Check that a simple page can be rendered via php-fpm.
        # If a service check happens to run while we are performing a
        # graceful restart of Apache, we want to try again before declaring
        # defeat.
        monitoring::service { 'appserver_http_php7':
            description    => 'PHP7 rendering',
            check_command  => 'check_http_wikipedia_main_php7',
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
    nrpe::plugin { 'nrpe_check_opcache':
        source => 'puppet:///modules/profile/mediawiki/php/nrpe_check_opcache.py',
    }

    if $monitor_opcache {
        nrpe::monitor_service { 'opcache':
            description  => 'PHP opcache health',
            nrpe_command => '/usr/local/lib/nagios/plugins/nrpe_check_opcache -w 100 -c 50',
            notes_url    => 'https://wikitech.wikimedia.org/wiki/Application_servers/Runbook#PHP7_opcache_health',
        }
    }
}
