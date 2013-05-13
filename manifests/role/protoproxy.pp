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
    include generic::sysctl::high-http-performance

    $nginx_worker_connections = '32768'
    $nginx_use_ssl = true

    file { '/etc/nginx/nginx.conf':
        content => template('nginx/nginx.conf.erb'),
        notify  => Service['nginx'],
        require => Package['nginx'],
    }

    file { '/etc/logrotate.d/nginx':
        content => template('nginx/logrotate'),
        require => Package['nginx'],
    }

}

# For production
class role::protoproxy::ssl {

    $cluster = "ssl"
    $enable_ipv6_proxy = true

    if $enable_ipv6_proxy {
        $desc = 'SSL and IPv6 proxy'
        } else {
            $desc = 'SSL proxy'
        }
        system_role { 'protoproxy::proxy_sites': description => $desc }

        include standard,
            certificates::wmf_ca,
            role::protoproxy::ssl::common,
            protoproxy::ganglia

        # Nagios monitoring
        monitor_service { "https": description => "HTTPS", check_command => "check_ssl_cert!*.wikimedia.org", critical => true }

        # FIXME: pull from lvs::configuration
        class { 'lvs::realserver':
            realserver_ips => $::site ? {
                'pmtpa' => [ '208.80.152.200', '208.80.152.201', '208.80.152.202', '208.80.152.203', '208.80.152.204', '208.80.152.205', '208.80.152.206', '208.80.152.207', '208.80.152.208', '208.80.152.209', '208.80.152.210', '208.80.152.211', '208.80.152.3', '208.80.152.118', '208.80.152.218', '208.80.152.219', '2620:0:860:ed1a::', '2620:0:860:ed1a::1', '2620:0:860:ed1a::2', '2620:0:860:ed1a::3', '2620:0:860:ed1a::4', '2620:0:860:ed1a::5', '2620:0:860:ed1a::6', '2620:0:860:ed1a::7', '2620:0:860:ed1a::8', '2620:0:860:ed1a::9', '2620:0:860:ed1a::a', '2620:0:860:ed1a::b', '2620:0:860:ed1a::c', '2620:0:860:ed1a::12', '2620:0:860:ed1a::13' ],
                'eqiad' => [ '208.80.154.224', '208.80.154.225', '208.80.154.226', '208.80.154.227', '208.80.154.228', '208.80.154.229', '208.80.154.230', '208.80.154.231', '208.80.154.232', '208.80.154.233', '208.80.154.234', '208.80.154.235', '208.80.154.236', '208.80.154.242', '208.80.154.243', '2620:0:861:ed1a::', '2620:0:861:ed1a::1', '2620:0:861:ed1a::2', '2620:0:861:ed1a::3', '2620:0:861:ed1a::4', '2620:0:861:ed1a::5', '2620:0:861:ed1a::6', '2620:0:861:ed1a::7', '2620:0:861:ed1a::8', '2620:0:861:ed1a::9', '2620:0:861:ed1a::a', '2620:0:861:ed1a::b', '2620:0:861:ed1a::c', '2620:0:861:ed1a::12', '2620:0:861:ed1a::13' ],
                'esams' => [ '91.198.174.224', '91.198.174.225', '91.198.174.233', '91.198.174.234', '91.198.174.226', '91.198.174.227', '91.198.174.228', '91.198.174.229', '91.198.174.230', '91.198.174.231', '91.198.174.232', '91.198.174.235', '2620:0:862:ed1a::', '2620:0:862:ed1a::1', '2620:0:862:ed1a::2', '2620:0:862:ed1a::3', '2620:0:862:ed1a::4', '2620:0:862:ed1a::5', '2620:0:862:ed1a::6', '2620:0:862:ed1a::7', '2620:0:862:ed1a::8', '2620:0:862:ed1a::9', '2620:0:862:ed1a::a', '2620:0:862:ed1a::b', '2620:0:862:ed1a::c' ],
            }
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
            proxy_addresses   => {
                'pmtpa' => [ '208.80.152.200', '[2620:0:860:ed1a::]' ],
                'eqiad' => [ '208.80.154.224', '[2620:0:861:ed1a::]' ],
                'esams' => [ '91.198.174.224', '[2620:0:862:ed1a::]' ],
            },
            proxy_server_name => '*.wikimedia.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend     => {
                'pmtpa' => { 'primary' => '10.2.1.25' },
                'eqiad' => { 'primary' => '10.2.2.25' },
                'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.200' },
            },
            ipv6_enabled       => true,
            enabled => true,
            proxy_listen_flags => 'default ssl',
        }
        protoproxy{ 'bits':
            proxy_addresses => {
                'pmtpa' => [ '208.80.152.210', '[2620:0:860:ed1a::a]' ],
                'eqiad' => [ '208.80.154.234', '[2620:0:861:ed1a::a]' ],
                'esams' => [ '91.198.174.233', '[2620:0:862:ed1a::a]' ],
            },
            proxy_server_name => 'bits.wikimedia.org geoiplookup.wikimedia.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend => {
                'pmtpa' => { 'primary' => '10.2.1.23' },
                'eqiad' => { 'primary' => '10.2.2.23' },
                'esams' => { 'primary' => '10.2.3.23', 'secondary' => '208.80.152.210' },
            },
            ipv6_enabled => true,
            enabled => true,
        }
        protoproxy{ 'upload':
            proxy_addresses => {
                'pmtpa' => [ '208.80.152.211', '[2620:0:860:ed1a::b]' ],
                'eqiad' => [ '208.80.154.235', '[2620:0:861:ed1a::b]' ],
                'esams' => [ '91.198.174.234', '[2620:0:862:ed1a::b]' ],
            },
            proxy_server_name => 'upload.wikimedia.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend => {
                'pmtpa' => { 'primary' => '10.2.1.24' },
                'eqiad' => { 'primary' => '10.2.2.24' },
                'esams' => { 'primary' => '10.2.3.24', 'secondary' => '208.80.152.211' },
            },
            ipv6_enabled => true,
            enabled => true,
        }
        protoproxy{ 'wikipedia':
            proxy_addresses => {
                'pmtpa' => [ '208.80.152.201', '[2620:0:860:ed1a::1]' ],
                'eqiad' => [ '208.80.154.225', '[2620:0:861:ed1a::1]' ],
                'esams' => [ '91.198.174.225', '[2620:0:862:ed1a::1]' ],
            },
            proxy_server_name => '*.wikipedia.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend => {
                'pmtpa' => { 'primary' => '10.2.1.25' },
                'eqiad' => { 'primary' => '10.2.2.25' },
                'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.201' },
            },
            ipv6_enabled => true,
            enabled => true,
        }
        protoproxy{ 'wiktionary':
            proxy_addresses => {
                'pmtpa' => [ '208.80.152.202', '[2620:0:860:ed1a::2]' ],
                'eqiad' => [ '208.80.154.226', '[2620:0:861:ed1a::2]' ],
                'esams' => [ '91.198.174.226', '[2620:0:862:ed1a::2]' ],
            },
            proxy_server_name => '*.wiktionary.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend => {
                'pmtpa' => { 'primary' => '10.2.1.25' },
                'eqiad' => { 'primary' => '10.2.2.25' },
                'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.202' },
            },
            ipv6_enabled => true,
            enabled => true,
        }
        protoproxy{ 'wikiquote':
            proxy_addresses => {
                'pmtpa' => [ '208.80.152.203', '[2620:0:860:ed1a::3]' ],
                'eqiad' => [ '208.80.154.227', '[2620:0:861:ed1a::3]' ],
                'esams' => [ '91.198.174.227', '[2620:0:862:ed1a::3]' ],
            },
            proxy_server_name => '*.wikiquote.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend => {
                'pmtpa' => { 'primary' => '10.2.1.25' },
                'eqiad' => { 'primary' => '10.2.2.25' },
                'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.203' },
            },
            ipv6_enabled => true,
            enabled => true,
        }
        protoproxy{ 'wikibooks':
            proxy_addresses => {
                'pmtpa' => [ '208.80.152.204', '[2620:0:860:ed1a::4]' ],
                'eqiad' => [ '208.80.154.228', '[2620:0:861:ed1a::4]' ],
                'esams' => [ '91.198.174.228', '[2620:0:862:ed1a::4]' ],
            },
            proxy_server_name => '*.wikibooks.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend => {
                'pmtpa' => { 'primary' => '10.2.1.25' },
                'eqiad' => { 'primary' => '10.2.2.25' },
                'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.204' },
            },
            ipv6_enabled => true,
            enabled => true,
        }
        protoproxy{ 'wikisource':
            proxy_addresses => {
                'pmtpa' => [ '208.80.152.205', '[2620:0:860:ed1a::5]' ],
                'eqiad' => [ '208.80.154.229', '[2620:0:861:ed1a::5]' ],
                'esams' => [ '91.198.174.229', '[2620:0:862:ed1a::5]' ],
            },
            proxy_server_name => '*.wikisource.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend => {
                'pmtpa' => { 'primary' => '10.2.1.25' },
                'eqiad' => { 'primary' => '10.2.2.25' },
                'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.205' },
            },
            ipv6_enabled => true,
            enabled => true,
        }
        protoproxy{ 'wikinews':
            proxy_addresses => {
                'pmtpa' => [ '208.80.152.206', '[2620:0:860:ed1a::6]' ],
                'eqiad' => [ '208.80.154.230', '[2620:0:861:ed1a::6]' ],
                'esams' => [ '91.198.174.230', '[2620:0:862:ed1a::6]' ],
            },
            proxy_server_name => '*.wikinews.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend => {
                'pmtpa' => { 'primary' => '10.2.1.25' },
                'eqiad' => { 'primary' => '10.2.2.25' },
                'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.206' },
            },
            ipv6_enabled => true,
            enabled => true,
        }
        protoproxy{ 'wikiversity':
            proxy_addresses => {
                'pmtpa' => [ '208.80.152.207', '[2620:0:860:ed1a::7]' ],
                'eqiad' => [ '208.80.154.231', '[2620:0:861:ed1a::7]' ],
                'esams' => [ '91.198.174.231', '[2620:0:862:ed1a::7]' ],
            },
            proxy_server_name => '*.wikiversity.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend => {
                'pmtpa' => { 'primary' => '10.2.1.25' },
                'eqiad' => { 'primary' => '10.2.2.25' },
                'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.207' },
            },
            ipv6_enabled => true,
            enabled => true,
        }
        protoproxy{ 'mediawiki':
            proxy_addresses => {
                'pmtpa' => [ '208.80.152.208', '[2620:0:860:ed1a::8]' ],
                'eqiad' => [ '208.80.154.232', '[2620:0:861:ed1a::8]' ],
                'esams' => [ '91.198.174.232', '[2620:0:862:ed1a::8]' ],
            },
            proxy_server_name => '*.mediawiki.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend => {
                'pmtpa' => { 'primary' => '10.2.1.25' },
                'eqiad' => { 'primary' => '10.2.2.25' },
                'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.208' },
            },
            ipv6_enabled => true,
            enabled => true,
        }
        protoproxy{ 'wikimediafoundation':
            proxy_addresses => {
                'pmtpa' => [ '208.80.152.209', '[2620:0:860:ed1a::9]' ],
                'eqiad' => [ '208.80.154.233', '[2620:0:861:ed1a::9]' ],
                'esams' => [ '91.198.174.235', '[2620:0:862:ed1a::9]' ],
            },
            proxy_server_name => '*.wikimediafoundation.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend => {
                'pmtpa' => { 'primary' => '10.2.1.25' },
                'eqiad' => { 'primary' => '10.2.2.25' },
                'esams' => { 'primary' => '10.2.3.25', 'secondary' => '208.80.152.209' },
            },
            ipv6_enabled => true,
            enabled => true,
        }
        protoproxy{ 'mobilewikipedia':
            proxy_addresses => {
                'pmtpa' => [ '127.0.0.1', '[2620:0:860:ed1a::c]' ],
                'eqiad' => [ '208.80.154.236', '[2620:0:861:ed1a::c]' ],
                'esams' => [ '127.0.0.1', '[2620:0:862:ed1a::c]' ],
            },
            proxy_server_name => '*.m.wikipedia.org',
            proxy_server_cert_name => 'unified.wikimedia.org',
            proxy_backend => {
                'pmtpa' => { 'primary' => '10.2.1.26' },
                'eqiad' => { 'primary' => '10.2.2.26' },
                'esams' => { 'primary' => '10.2.3.26', 'secondary' => '208.80.154.236' },
            },
            ipv6_enabled => true,
            enabled => true,
        }
        # wikidata.org
        if $::site != 'esams' {
            protoproxy{ 'wikidata':
                proxy_addresses => {
                    'pmtpa' => [ '208.80.152.218', '[2620:0:860:ed1a::12]' ],
                    'eqiad' => [ '208.80.154.242', '[2620:0:861:ed1a::12]' ],
                    # 'esams' => [ '127.0.0.1' ],
                    },
                    proxy_server_name => '*.wikidata.org',
                    proxy_server_cert_name => 'unified.wikimedia.org',
                    proxy_backend => {
                        'pmtpa' => { 'primary' => '10.2.1.25' },
                        'eqiad' => { 'primary' => '10.2.2.25' },
                        # 'esams' => { 'primary' => '10.2.3.25' },
                        },
                        ipv6_enabled => true,
                        enabled => true,
            }
        }
        # wikivoyage.org
        if $::site != 'esams' {
            protoproxy{ 'wikivoyage':
                proxy_addresses => {
                    'pmtpa' => [ '208.80.152.219', '[2620:0:860:ed1a::13]' ],
                    'eqiad' => [ '208.80.154.243', '[2620:0:861:ed1a::13]' ],
                    # 'esams' => [ '127.0.0.1' ],
                    },
                    proxy_server_name => '*.wikivoyage.org',
                    proxy_server_cert_name => 'unified.wikimedia.org',
                    proxy_backend => {
                        'pmtpa' => { 'primary' => '10.2.1.25' },
                        'eqiad' => { 'primary' => '10.2.2.25' },
                        # 'esams' => { 'primary' => '10.2.3.25' },
                        },
                        ipv6_enabled => true,
                        enabled => true,
            }
        }
        # Misc services
        protoproxy{ 'videos':
            proxy_addresses => {
                'pmtpa' => [ '208.80.152.200', '[2620:0:860:2::80:2]' ],
                'eqiad' => [ '208.80.154.224', '[2620:0:862:3::80:2]' ],
                'esams' => [ '91.198.174.224', '[2620:0:862:1::80:2]' ] },
                proxy_server_name => 'videos.wikimedia.org',
                proxy_server_cert_name => 'unified.wikimedia.org',
                proxy_backend => {
                    'pmtpa' => { 'primary' => '10.64.16.146' },
                    'eqiad' => { 'primary' => '10.64.16.146' },
                    'esams' => { 'primary' => '208.80.152.200', 'secondary' => '208.80.152.200' },
                },
                ssl_backend => { 'esams' => 'true' },
                enabled => true,
        }

}

class role::protoproxy::ssl::beta::common {
    $cluster = 'ssl'
    $enable_ipv6_proxy = false

    include standard,
        certificates::wmf_labs_ca,
        role::protoproxy::ssl::common

    install_certificate { 'star.wmflabs.org': }

}

# Because beta does not have a frontend LVS to redirect the requests
# made to port 443, we have to setup a nginx proxy on each of the caches.
# Nginx will listen on the real instance IP, proxy_addresses are not needed.
#
class role::protoproxy::ssl::beta {

    system_role { 'role::protoproxy::ssl:beta::bits': description => 'SSL proxy on beta' }

    include role::protoproxy::ssl::beta::common

    # protoproxy::instance parameters common to any beta instance
    $defaults = {
        proxy_server_cert_name => 'star.wmflabs.org',
        proxy_backend => {
            # send all traffic to the local cache
            'pmtpa' => { 'primary' => '127.0.0.1' }
        },
        ipv6_enabled => false,
        enabled => true,
    }

    $instances = {
        'bits' => { proxy_server_name => 'bits.beta.wmflabs.org' },
    }

    create_resources( protoproxy, $instances, $defaults )

}
