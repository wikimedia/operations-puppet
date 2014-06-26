# vim:sw=4:ts=4:et:

# Wikimedia roles for HTTPS proxies
#
# In production, requests made on port 443 are redirected by the LVS frontends
# to a pool of Nginx proxies.  They are terminating the SSL connection and
# reinject the request as HTTP.
#
# The beta cluster also supports HTTPS though in a slightly different setup
# since labs is lacking LVS support.  Instead the requests on port 443 are
# handled on each of the caches which have a local nginx proxy terminating
# the SSL connection and reinject the request on the instance IP address.

# Basic nginx and server setup. Shared by both production and labs.
#
# Requires:
# - nginx package
class role::protoproxy::ssl::common {

    # Tune kernel settings
    include webserver::base

    $nginx_worker_connections = '32768'
    $nginx_use_ssl = true

    class { 'nginx': managed => false, }

    file { '/etc/nginx/nginx.conf':
        content => template('nginx/nginx.conf.erb'),
        require => Class['nginx'],
    }

    file { '/etc/logrotate.d/nginx':
        content => template('nginx/logrotate'),
    }

}

# For production
class role::protoproxy::ssl {
    include lvs::configuration

    class {'protoproxy::params': enable_ipv6_proxy => true }

    if $protoproxy::params::enable_ipv6_proxy {
        $desc = 'SSL and IPv6 proxy'
    } else {
        $desc = 'SSL proxy'
    }
    system::role { 'protoproxy::proxy_sites': description => $desc }

    include standard,
        certificates::wmf_ca,
        role::protoproxy::ssl::common,
        protoproxy::ganglia

    # Nagios monitoring
    monitor_service { 'https': description => 'HTTPS', check_command => 'check_ssl_cert!*.wikipedia.org', critical => true }

    class { 'lvs::realserver':
        realserver_ips => $lvs::configuration::lvs_service_ips[$::realm]['https'][$::site]
    }

    install_certificate{ 'star.wikimedia.org': }
    install_certificate{ 'star.wikipedia.org': }
    install_certificate{ 'star.wiktionary.org': }
    install_certificate{ 'star.wikiquote.org': }
    install_certificate{ 'star.wikibooks.org': }
    install_certificate{ 'star.wikisource.org': }
    install_certificate{ 'star.wikinews.org': }
    install_certificate{ 'star.wikiversity.org': }
    install_certificate{ 'star.mediawiki.org': }
    install_certificate{ 'star.wikimediafoundation.org': }
    install_certificate{ 'star.wikidata.org': }
    install_certificate{ 'star.wikivoyage.org': }
    install_certificate{ 'unified.wikimedia.org': }

    protoproxy{ 'wikimedia':
        proxy_addresses        => {
            'eqiad' => [ '208.80.154.224', '[2620:0:861:ed1a::]' ],
            'esams' => [ '91.198.174.192', '91.198.174.201', '91.198.174.224', '[2620:0:862:ed1a::1:9]' ],
        },
        proxy_server_name      => '*.wikimedia.org',
        proxy_server_cert_name => 'unified.wikimedia.org',
        proxy_backend          => {
            'eqiad' => { 'primary'                                                         => '10.2.2.25' },
            'esams' => { 'primary'                                                         => '10.2.3.25', 'secondary' => '208.80.154.224' },
        },
        ipv6_enabled           => true,
        enabled                => true,
        proxy_listen_flags     => 'default ssl',
    }
    protoproxy{ 'bits':
        proxy_addresses        => {
            'eqiad' => [ '208.80.154.234', '[2620:0:861:ed1a::1:a]', '[2620:0:861:ed1a::a]' ],
            'esams' => [ '91.198.174.202', '91.198.174.233', '[2620:0:862:ed1a::1:a]', '[2620:0:862:ed1a::a]' ],
        },
        proxy_server_name      => 'bits.wikimedia.org geoiplookup.wikimedia.org',
        proxy_server_cert_name => 'unified.wikimedia.org',
        proxy_backend          => {
            'eqiad' => { 'primary'                                                         => '10.2.2.23' },
            'esams' => { 'primary'                                                         => '10.2.3.23', 'secondary' => '208.80.154.234' },
        },
        ipv6_enabled           => true,
        enabled                => true,
    }
    protoproxy{ 'upload':
        proxy_addresses        => {
            'eqiad' => [ '208.80.154.240', '[2620:0:861:ed1a::2:b]' ],
            'esams' => [ '91.198.174.208', '[2620:0:862:ed1a::2:b]' ],
        },
        proxy_server_name      => 'upload.wikimedia.org',
        proxy_server_cert_name => 'unified.wikimedia.org',
        proxy_backend          => {
            'eqiad' => { 'primary'                                                         => '10.2.2.24' },
            'esams' => { 'primary'                                                         => '10.2.3.24', 'secondary' => '208.80.154.240' },
        },
        ipv6_enabled           => true,
        enabled                => true,
    }
    protoproxy{ 'wikipedia':
        proxy_addresses        => {
            'eqiad' => [ '208.80.154.225', '[2620:0:861:ed1a::1]' ],
            'esams' => [ '[2620:0:862:ed1a::1]' ],
        },
        proxy_server_name      => '*.wikipedia.org',
        proxy_server_cert_name => 'unified.wikimedia.org',
        proxy_backend          => {
            'eqiad' => { 'primary'                                                         => '10.2.2.25' },
            'esams' => { 'primary'                                                         => '10.2.3.25', 'secondary' => '208.80.154.224' },
        },
        ipv6_enabled           => true,
        enabled                => true,
    }
    protoproxy{ 'wiktionary':
        proxy_addresses        => {
            'eqiad' => [ '208.80.154.226', '[2620:0:861:ed1a::2]' ],
            'esams' => [],
        },
        proxy_server_name      => '*.wiktionary.org',
        proxy_server_cert_name => 'unified.wikimedia.org',
        proxy_backend          => {
            'eqiad' => { 'primary'                                                         => '10.2.2.25' },
            'esams' => { 'primary'                                                         => '10.2.3.25', 'secondary' => '208.80.154.224' },
        },
        ipv6_enabled           => true,
        enabled                => true,
    }
    protoproxy{ 'wikiquote':
        proxy_addresses        => {
            'eqiad' => [ '208.80.154.227', '[2620:0:861:ed1a::3]' ],
            'esams' => [],
        },
        proxy_server_name      => '*.wikiquote.org',
        proxy_server_cert_name => 'unified.wikimedia.org',
        proxy_backend          => {
            'eqiad' => { 'primary'                                                         => '10.2.2.25' },
            'esams' => { 'primary'                                                         => '10.2.3.25', 'secondary' => '208.80.154.224' },
        },
        ipv6_enabled           => true,
        enabled                => true,
    }
    protoproxy{ 'wikibooks':
        proxy_addresses        => {
            'eqiad' => [ '208.80.154.228', '[2620:0:861:ed1a::4]' ],
            'esams' => [],
        },
        proxy_server_name      => '*.wikibooks.org',
        proxy_server_cert_name => 'unified.wikimedia.org',
        proxy_backend          => {
            'eqiad' => { 'primary'                                                         => '10.2.2.25' },
            'esams' => { 'primary'                                                         => '10.2.3.25', 'secondary' => '208.80.154.224' },
        },
        ipv6_enabled           => true,
        enabled                => true,
    }
    protoproxy{ 'wikisource':
        proxy_addresses        => {
            'eqiad' => [ '208.80.154.229', '[2620:0:861:ed1a::5]' ],
            'esams' => [],
        },
        proxy_server_name      => '*.wikisource.org',
        proxy_server_cert_name => 'unified.wikimedia.org',
        proxy_backend          => {
            'eqiad' => { 'primary'                                                         => '10.2.2.25' },
            'esams' => { 'primary'                                                         => '10.2.3.25', 'secondary' => '208.80.154.224' },
        },
        ipv6_enabled           => true,
        enabled                => true,
    }
    protoproxy{ 'wikinews':
        proxy_addresses        => {
            'eqiad' => [ '208.80.154.230', '[2620:0:861:ed1a::6]' ],
            'esams' => [],
        },
        proxy_server_name      => '*.wikinews.org',
        proxy_server_cert_name => 'unified.wikimedia.org',
        proxy_backend          => {
            'eqiad' => { 'primary'                                                         => '10.2.2.25' },
            'esams' => { 'primary'                                                         => '10.2.3.25', 'secondary' => '208.80.154.224' },
        },
        ipv6_enabled           => true,
        enabled                => true,
    }
    protoproxy{ 'wikiversity':
        proxy_addresses        => {
            'eqiad' => [ '208.80.154.231', '[2620:0:861:ed1a::7]' ],
            'esams' => [],
        },
        proxy_server_name      => '*.wikiversity.org',
        proxy_server_cert_name => 'unified.wikimedia.org',
        proxy_backend          => {
            'eqiad' => { 'primary'                                                         => '10.2.2.25' },
            'esams' => { 'primary'                                                         => '10.2.3.25', 'secondary' => '208.80.154.224' },
        },
        ipv6_enabled           => true,
        enabled                => true,
    }
    protoproxy{ 'mediawiki':
        proxy_addresses        => {
            'eqiad' => [ '208.80.154.232', '[2620:0:861:ed1a::8]' ],
            'esams' => [],
        },
        proxy_server_name      => '*.mediawiki.org',
        proxy_server_cert_name => 'unified.wikimedia.org',
        proxy_backend          => {
            'eqiad' => { 'primary'                                                         => '10.2.2.25' },
            'esams' => { 'primary'                                                         => '10.2.3.25', 'secondary' => '208.80.154.224' },
        },
        ipv6_enabled           => true,
        enabled                => true,
    }
    protoproxy{ 'wikimediafoundation':
        proxy_addresses        => {
            'eqiad' => [ '208.80.154.233', '[2620:0:861:ed1a::9]' ],
            'esams' => [],
        },
        proxy_server_name      => '*.wikimediafoundation.org',
        proxy_server_cert_name => 'unified.wikimedia.org',
        proxy_backend          => {
            'eqiad' => { 'primary'                                                         => '10.2.2.25' },
            'esams' => { 'primary'                                                         => '10.2.3.25', 'secondary' => '208.80.154.224' },
        },
        ipv6_enabled           => true,
        enabled                => true,
    }
    protoproxy{ 'mobilewikipedia':
        proxy_addresses        => {
            'eqiad' => [ '208.80.154.236', '[2620:0:861:ed1a::1:c]', '[2620:0:861:ed1a::c]' ],
            'esams' => [ '91.198.174.204', '91.198.174.236', '[2620:0:862:ed1a::1:c]', '[2620:0:862:ed1a::c]' ],
        },
        proxy_server_name      => '*.m.wikipedia.org',
        proxy_server_cert_name => 'unified.wikimedia.org',
        proxy_backend          => {
            'eqiad' => { 'primary'                                                         => '10.2.2.26' },
            'esams' => { 'primary'                                                         => '10.2.3.26', 'secondary' => '208.80.154.236' },
        },
        ipv6_enabled           => true,
        enabled                => true,
    }
    # wikidata.org
    protoproxy{ 'wikidata':
        proxy_addresses            => {
            'eqiad'     => [ '208.80.154.242', '[2620:0:861:ed1a::12]' ],
            'esams'     => [],
            },
            proxy_server_name      => '*.wikidata.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend          => {
                'eqiad' => { 'primary'                                                         => '10.2.2.25' },
                'esams' => { 'primary'                                                         => '10.2.3.25', 'secondary' => '208.80.154.224' },
                },
                ipv6_enabled       => true,
                enabled            => true,
    }
    # wikivoyage.org
    protoproxy{ 'wikivoyage':
        proxy_addresses            => {
            'eqiad'     => [ '208.80.154.243', '[2620:0:861:ed1a::13]' ],
            'esams'     => [],
            },
            proxy_server_name      => '*.wikivoyage.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend          => {
                'eqiad' => { 'primary'                                                         => '10.2.2.25' },
                'esams' => { 'primary'                                                         => '10.2.3.25', 'secondary' => '208.80.154.224' },
                },
                ipv6_enabled       => true,
                enabled            => true,
    }
    # Misc services
    protoproxy{ 'videos':
        proxy_addresses            => {
            'eqiad'                             => [ '208.80.154.224', '[2620:0:862:3::80:2]' ],
            'esams'                             => [] },
            proxy_server_name      => 'videos.wikimedia.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend          => {
                'eqiad'                         => { 'primary'                                                         => '10.64.16.146' },
                'esams'                         => { 'primary'                                                         => '10.2.3.25', 'secondary' => '208.80.154.224' },
            },
            ssl_backend            => { 'esams' => true },
            enabled                => true,
    }
}

class role::protoproxy::ssl::beta::common {

    include standard,
        certificates::wmf_labs_ca,
        role::protoproxy::ssl::common

    install_certificate { 'star.wmflabs.org':
        privatekey => false,
    }

}

# Because beta does not have a frontend LVS to redirect the requests
# made to port 443, we have to setup a nginx proxy on each of the caches.
# Nginx will listen on the real instance IP, proxy_addresses are not needed.
#
class role::protoproxy::ssl::beta {

    # Don't run an ipv6 proxy on beta
    class {'protoproxy::params': enable_ipv6_proxy => false}


    system::role { 'role::protoproxy::ssl:beta': description => 'SSL proxy on beta' }

    include role::protoproxy::ssl::beta::common

    # protoproxy::instance parameters common to any beta instance
    $defaults = {
        proxy_server_cert_name => 'star.wmflabs.org',
        proxy_backend => {
            # send all traffic to the local cache
            'eqiad' => { 'primary' => '127.0.0.1' }
        },
        ipv6_enabled => false,
        enabled => true,
    }

    $instances = {
        'bits'        => { proxy_server_name => 'bits.beta.wmflabs.org' },
        'wikidata'    => { proxy_server_name => 'wikidata.beta.wmflabs.org' },
        'wikimedia'   => { proxy_server_name => '*.wikimedia.beta.wmflabs.org' },

        'wikibooks'   => { proxy_server_name => '*.wikibooks.beta.wmflabs.org' },
        'wikinews'    => { proxy_server_name => '*.wikinews.beta.wmflabs.org' },
        'wikipedia'   => { proxy_server_name => '*.wikipedia.beta.wmflabs.org' },
        'wikiquote'   => { proxy_server_name => '*.wikiquote.beta.wmflabs.org' },
        'wikisource'  => { proxy_server_name => '*.wikisource.beta.wmflabs.org' },
        'wikiversity' => { proxy_server_name => '*.wikiversity.beta.wmflabs.org' },
        'wikivoyage'  => { proxy_server_name => '*.wikivoyage.beta.wmflabs.org' },
        'wiktionary'  => { proxy_server_name => '*.wiktionary.beta.wmflabs.org' },
    }

    create_resources( protoproxy, $instances, $defaults )

}
