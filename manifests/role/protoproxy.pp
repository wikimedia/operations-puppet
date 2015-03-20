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
    include webserver::sysctl_settings

    $nginx_worker_connections = '32768'
    $nginx_use_ssl = true
    $nginx_ssl_conf = ssl_ciphersuite('nginx', 'compat')

    class { 'nginx': managed => false, }

    file { '/etc/nginx/nginx.conf':
        content => template('nginx/nginx.conf.erb'),
        tag     => 'nginx', # workaround PUP-2689, can remove w/ puppetmaster 3.6.2+
    }

    file { '/etc/logrotate.d/nginx':
        content => template('nginx/logrotate'),
        tag     => 'nginx', # workaround PUP-2689, can remove w/ puppetmaster 3.6.2+
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
