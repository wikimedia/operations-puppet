class profile::toolforge::proxy (
    Array[String] $proxies      = lookup('profile::toolforge::proxies', {default_value => ['tools-proxy-03']}),
    String        $active_proxy = lookup('profile::toolforge::active_proxy_host', {default_value => 'tools-proxy-03'}),
    Stdlib::Fqdn  $web_domain   = lookup('profile::toolforge::web_domain', {default_value => 'tools.wmflabs.org'}),
) {
    class { '::redis::client::python': }

    sslcert::certificate { 'star.wmflabs.org':
        ensure => absent,
    }
    acme_chief::cert { 'toolforge':
        puppet_rsc => Exec['nginx-reload'],
    }

    if $::hostname != $active_proxy {
        $redis_replication = {
            "${::hostname}" => $active_proxy,
        }
    } else {
        $redis_replication = undef
    }

    class { '::dynamicproxy':
        ssl_settings         => ssl_ciphersuite('nginx', 'compat'),
        luahandler           => 'urlproxy',
        ssl_certificate_name => 'toolforge',
        redis_replication    => $redis_replication,
        error_config         => {
            title       => 'Wikimedia Toolforge Error',
            logo        => '/.error/toolforge-logo.png',
            logo_2x     => '/.error/toolforge-logo-2x.png',
            logo_alt    => 'Wikimedia Toolforge',
            logo_height => 157,
            favicon     => '/.error/favicon.ico',
        },
        banned_description   => 'You have been banned from accessing Toolforge. Please see <a href="https://wikitech.wikimedia.org/wiki/Help:Toolforge/Banned">Help:Toolforge/Banned</a> for more information on why and on how to resolve this.',
        web_domain           => $web_domain,
        https_upgrade        => true,
        use_acme_chief       => true,
    }


    $proxy_nodes = join($proxies, ' ')

    # Open up redis to all proxies!
    ferm::service { 'redis-replication':
        proto  => 'tcp',
        port   => '6379',
        srange => "@resolve((${proxy_nodes}))",
    }

    file { '/usr/local/sbin/proxylistener':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/profile/toolforge/proxylistener.py',
        # Is provided by the dynamicproxy class.
        require => Class['::redis::client::python'],
    }

    systemd::service { 'proxylistener':
        ensure  => present,
        content => systemd_template('toolforge/proxylistener'),
        require => File['/usr/local/sbin/proxylistener'],
    }

    ferm::service { 'proxylistener-port':
        proto  => 'tcp',
        port   => '8282',
        srange => '$LABS_NETWORKS',
        desc   => 'Proxylistener port, open to just CloudVPS',
    }

    file { '/var/www/error/favicon.ico':
        ensure  => file,
        source  => 'puppet:///modules/profile/toolforge/favicon.ico',
        require => File['/var/www/error'],
    }

    file { '/var/www/error/toolforge-logo.png':
        ensure  => file,
        source  => 'puppet:///modules/profile/toolforge/toolforge-logo.png',
        require => [File['/var/www/error']],
    }

    file { '/var/www/error/toolforge-logo-2x.png':
        ensure  => file,
        source  => 'puppet:///modules/profile/toolforge/toolforge-logo-2x.png',
        require => [File['/var/www/error']],
    }

    require_package('goaccess')  # webserver statistics, T121233

    $graphite_metric_prefix = "${::labsproject}.reqstats"

    file { '/usr/local/lib/python2.7/dist-packages/toolsweblogster.py':
        source => 'puppet:///modules/profile/toolforge/toolsweblogster.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    logster::job { 'proxy-requests':
        minute          => '*/1',
        parser          => 'toolsweblogster.UrlFirstSegmentLogster', # Nothing more specific yet
        logfile         => '/var/log/nginx/access.log',
        logster_options => "-o statsd --statsd-host=labmon1001.eqiad.wmnet:8125 --metric-prefix=${graphite_metric_prefix}.",
        require         => File['/usr/local/lib/python2.7/dist-packages/toolsweblogster.py'],
    }

    ferm::service { 'proxymanager':
        proto  => 'tcp',
        port   => '8081',
        desc   => 'Proxymanager service for CloudVPS instances',
        srange => '$LABS_NETWORKS',
    }

    ferm::service{ 'http':
        proto => 'tcp',
        port  => '80',
        desc  => 'HTTP webserver for the entire world',
    }

    ferm::service{ 'https':
        proto => 'tcp',
        port  => '443',
        desc  => 'HTTPS webserver for the entire world',
    }
}
