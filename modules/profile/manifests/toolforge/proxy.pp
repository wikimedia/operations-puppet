class profile::toolforge::proxy (
    Array[String]       $proxies             = lookup('profile::toolforge::proxies',           {default_value => ['tools-proxy-03']}),
    String              $active_proxy        = lookup('profile::toolforge::active_proxy_host', {default_value => 'tools-proxy-03'}),
    Stdlib::Fqdn        $web_domain          = lookup('profile::toolforge::web_domain',        {default_value => 'toolforge.org'}),
    Array[Stdlib::Fqdn] $prometheus          = lookup('prometheus_nodes',                      {default_value => ['localhost']}),
    String              $statsd              = lookup('statsd',                                {default_value => 'localhost:8125'}),
    Stdlib::Fqdn        $k8s_vip_fqdn        = lookup('profile::toolforge::k8s::apiserver_fqdn',{default_value => 'k8s.tools.eqiad1.wikimedia.cloud'}),
    Stdlib::Port        $k8s_vip_port        = lookup('profile::toolforge::k8s::ingress_port', {default_value => 30000}),
    Integer             $rate_limit_requests = lookup('profile::toolforge::proxy::rate_limit_requests', {default_value => 100}),
) {
    class { '::redis::client::python': }

    $ssl_cert_name = 'toolforge'
    acme_chief::cert { $ssl_cert_name:
        puppet_rsc => Exec['nginx-reload'],
    }
    class { '::sslcert::dhparam': } # deploys /etc/ssl/dhparam.pem, required by nginx

    if $::hostname != $active_proxy {
        $redis_replication = {
            "${::hostname}" => $active_proxy,
        }
    } else {
        $redis_replication = undef
    }

    class { '::dynamicproxy':
        acme_certname       => $ssl_cert_name,
        ssl_settings        => ssl_ciphersuite('nginx', 'compat'),
        luahandler          => 'urlproxy',
        k8s_vip_fqdn        => $k8s_vip_fqdn,
        k8s_vip_fqdn_port   => $k8s_vip_port,
        redis_replication   => $redis_replication,
        error_config        => {
            title       => 'Wikimedia Toolforge Error',
            logo        => '/.error/toolforge-logo.png',
            logo_2x     => '/.error/toolforge-logo-2x.png',
            logo_alt    => 'Wikimedia Toolforge',
            logo_height => 120,
            logo_width  => 120,
            logo_link   => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge',
            favicon     => '/.error/favicon.ico',
        },
        banned_description  => 'You have been banned from accessing Toolforge. Please see <a href="https://wikitech.wikimedia.org/wiki/Help:Toolforge/Banned">Help:Toolforge/Banned</a> for more information on why and on how to resolve this.',
        rate_limit_requests => $rate_limit_requests,
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

    file { '/var/www/error/robots.txt':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/robots.txt',
        owner  => 'www-data',
        group  => 'www-data',
        mode   => '0444',
    }

    ensure_packages('goaccess')  # webserver statistics, T121233

    $graphite_metric_prefix = "${::labsproject}.reqstats"

    file { '/usr/local/lib/python2.7/dist-packages/toolsweblogster.py':
        source => 'puppet:///modules/profile/toolforge/toolsweblogster.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    logster::job { 'proxy-requests':
        minute          => '0/1',
        parser          => 'toolsweblogster.UrlFirstSegmentLogster', # Nothing more specific yet
        logfile         => '/var/log/nginx/access.log',
        logster_options => "-o statsd --statsd-host=${statsd} --metric-prefix=${graphite_metric_prefix}.",
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

    ferm::service { 'https':
        proto => 'tcp',
        port  => '443',
        desc  => 'HTTPS webserver for the entire world',
    }

    # prometheus nginx metrics
    class { 'prometheus::nginx_exporter': }

    $prometheus_hosts = join($prometheus, ' ')
    ferm::service { 'prometheus_nginx_exporter':
        proto  => 'tcp',
        port   => '9113', # this is the default
        desc   => 'prometheus nginx exporter',
        srange => "@resolve((${prometheus_hosts}))",
    }

    prometheus::blackbox::check::http { $web_domain:
        path                => '/.well-known/healthz',
        ip_families         => ['ip4'],
        prometheus_instance => 'tools',
        team                => 'wmcs',
        severity            => 'warning',
    }
}
