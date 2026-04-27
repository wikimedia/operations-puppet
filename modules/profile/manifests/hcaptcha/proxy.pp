# SPDX-License-Identifier: Apache-2.0
# @ summary Reverse proxy for hCaptcha for hCaptcha service T397841
#
# @param proxy_domain The domain name for the hCaptcha proxy.
# @param header_acao set Access-Control-Allow-Origin
# @param subdomains A hash of subdomains to be created, mapping prefix to target.
# @param ip_hash_salt Salt used for IP address hashing
# @param nginx_ipblinding_conf additional configuration rendered in
#        profile/hcaptcha/proxy.nginx.conf.erb P78219
class profile::hcaptcha::proxy (
    Stdlib::Port          $proxy_port             = lookup('profile::hcaptcha::proxy::proxy_port'),
    Stdlib::Fqdn          $proxy_domain           = lookup('profile::hcaptcha::proxy::proxy_domain'),
    Hash[String, String]  $subdomains             = lookup('profile::hcaptcha::proxy::subdomains'),
    Array[Stdlib::Host,1] $nginx_resolvers        = lookup('profile::hcaptcha::proxy::nginx_resolvers'),
    String                $ip_hash_salt           = lookup('profile::hcaptcha::proxy::ip_hash_salt'),
    String                $hcaptcha_sitekey       = lookup('profile::hcaptcha::hcaptcha_sitekey'),
    String                $hcaptcha_secret        = lookup('profile::hcaptcha::hcaptcha_secret'),
    String                $nginx_ipblinding_conf  = lookup('profile::hcaptcha::proxy::nginx_ipblinding_conf'),
    String                $nginx_private_conf     = lookup('profile::hcaptcha::proxy::nginx_private_conf'),
    Array[Stdlib::Fqdn]   $wikimedia_domains      = lookup('profile::hcaptcha::proxy::wikimedia_domains'),
) {

    include network::constants

    firewall::service { 'hcaptcha-proxy':
        proto    => 'tcp',
        port     => $proxy_port,
        src_sets => ['PRODUCTION_NETWORKS'],
    }

    class { 'sslcert::dhparam': }

    $nginx_resolver_ips = wmflib::hosts2ips($nginx_resolvers)

    file { '/etc/nginx/nginx.conf':
        content => template('profile/hcaptcha/nginx.conf.erb'),
        tag     => 'nginx',
    }

    file { '/etc/nginx/lua':
        ensure => directory,
    }

    file { '/etc/nginx/lua/filter_set_cookie.lua':
        content => file('profile/hcaptcha/filter_set_cookie.lua'),
        tag     => 'nginx',
        require => File['/etc/nginx/lua'],
    }

    # Allow each subdomain of known Wikimedia domains to embed iframes from the hcaptcha proxy.
    $csp_origins = $wikimedia_domains.map |$domain| { "https://*.${domain}" }.join(' ')

    $ssl_paths = profile::pki::get_cert('discovery2026', $proxy_domain, {
        'owner'           => 'root',
        'group'           => 'www-data',
        'notify_services' => ['nginx'],
    })
    $ssl_key   = $ssl_paths['key']
    $ssl_chain = $ssl_paths['chained']
    nginx::site { $proxy_domain:
        content => template('profile/hcaptcha/proxy.nginx.conf.erb'),
        notify  => Exec['nginx-reload'],
    }

    $subdomains.each |$prefix, $target| {
        $subdomain = "${prefix}-${proxy_domain}"
        $subdomain_ssl_paths = profile::pki::get_cert('discovery2026', $subdomain, {
            'owner'           => 'root',
            'group'           => 'www-data',
            'notify_services' => ['nginx'],
        })
        $subdomain_ssl_key = $subdomain_ssl_paths['key']
        $subdomain_ssl_chain = $subdomain_ssl_paths['chained']
        nginx::site { $subdomain:
            content => template('profile/hcaptcha/subdomain.nginx.conf.erb'),
            notify  => Exec['nginx-reload'],
        }
    }

    # Mtail program to gather metrics
    class { '::mtail':
        logs  => ['/var/log/nginx/access.log'],
        group => 'adm',
    }
    mtail::program { 'nginx_hcaptcha_access_log':
        ensure => present,
        source => 'puppet:///modules/mtail/programs/nginx_upstream_time.mtail',
    }
    profile::auto_restarts::service { 'nginx': }
    class { 'prometheus::nginx_exporter': }
    # error logs are streamed to logstash
    rsyslog::input::file { 'hcaptcha-nginx-error':
        path => '/var/log/nginx/error.log',
    }


}
