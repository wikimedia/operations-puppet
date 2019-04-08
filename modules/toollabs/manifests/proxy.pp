# A dynamic HTTP routing proxy, based on the dynamicproxy module.

class toollabs::proxy(
    $ssl_certificate_name = 'star.wmflabs.org',
    $ssl_install_certificate = true,
    $web_domain = 'tools.wmflabs.org',
    $proxies = ['tools-proxy-03', 'tools-proxy-04'],
) {

    include ::toollabs::infrastructure
    include ::redis::client::python

    if $ssl_install_certificate {
        sslcert::certificate { $ssl_certificate_name:
            before       => Class['::dynamicproxy'],
        }
    }

    $active_proxy = hiera('active_proxy_host')

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
        ssl_certificate_name => $ssl_certificate_name,
        redis_replication    => $redis_replication,
        error_config         => {
            title       => 'Wikimedia Toolforge Error',
            logo        => '/.error/tool-labs-logo.png',
            logo_2x     => '/.error/tool-labs-logo-2x.png',
            logo_alt    => 'Wikimedia Toolforge',
            logo_height => 157,
            favicon     => '/.error/favicon.ico',
        },
        banned_description   => 'You have been banned from accessing Toolforge. Please see <a href="https://wikitech.wikimedia.org/wiki/Help:Toolforge/Banned">Help:Toolforge/Banned</a> for more information on why and on how to resolve this.',
        web_domain           => $web_domain,
        https_upgrade        => true,
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
        source  => 'puppet:///modules/toollabs/proxylistener.py',
        # Is provided by the dynamicproxy class.
        require => Class['::redis::client::python'],
    }

    base::service_unit { 'proxylistener':
        ensure  => present,
        upstart => upstart_template('proxylistener'),
        systemd => systemd_template('proxylistener'),
        require => File['/usr/local/sbin/proxylistener'],
    }

    ferm::service { 'proxylistener-port':
        proto  => 'tcp',
        port   => '8282',
        srange => '$LABS_NETWORKS',
        desc   => 'Proxylistener port, open to just labs',
    }

    file { '/var/www/error/favicon.ico':
        ensure  => file,
        source  => 'puppet:///modules/toollabs/favicon.ico',
        require => File['/var/www/error'],
    }

    file { '/var/www/error/tool-labs-logo.png':
        ensure  => file,
        source  => 'puppet:///modules/toollabs/tool-labs-logo.png',
        require => [File['/var/www/error']],
    }

    file { '/var/www/error/tool-labs-logo-2x.png':
        ensure  => file,
        source  => 'puppet:///modules/toollabs/tool-labs-logo-2x.png',
        require => [File['/var/www/error']],
    }

    require_package('goaccess')  # webserver statistics, T121233

    $graphite_metric_prefix = "${::labsproject}.reqstats"

    file { '/usr/local/lib/python2.7/dist-packages/toolsweblogster.py':
        source => 'puppet:///modules/toollabs/toolsweblogster.py',
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
}
