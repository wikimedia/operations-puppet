# SPDX-License-Identifier: Apache-2.0
# Class: profile::hcaptcha::proxy
#
class profile::hcaptcha::proxy (
    Stdlib::Port          $proxy_port            = lookup('profile::hcaptcha::proxy::proxy_port'),
    Stdlib::Fqdn          $proxy_domain          = lookup('profile::hcaptcha::proxy::proxy_domain'),
    Hash[String, String]  $subdomains            = lookup('profile::hcaptcha::proxy::subdomains'),
    Array[Stdlib::Host,1] $nginx_resolvers       = lookup('profile::hcaptcha::proxy::nginx_resolvers'),
    String                $ip_hash_salt          = lookup('profile::hcaptcha::proxy::ip_hash_salt'),
    String                $hcaptcha_sitekey      = lookup('profile::hcaptcha::hcaptcha_sitekey'),
    String                $hcaptcha_secret       = lookup('profile::hcaptcha::hcaptcha_secret'),
    String                $nginx_ipblinding_conf = lookup('profile::hcaptcha::proxy::nginx_ipblinding_conf'),
    String                $nginx_private_conf    = lookup('profile::hcaptcha::proxy::nginx_private_conf'),
) {

    include network::constants

    ferm::service { 'hcaptcha-proxy':
        proto => 'tcp',
        port  => $proxy_port,
    }

    class { 'sslcert::dhparam': }

    $nginx_resolver_ips = wmflib::hosts2ips($nginx_resolvers)

    file { '/etc/nginx/nginx.conf':
        content => template('profile/hcaptcha/nginx.conf.erb'),
        tag     => 'nginx',
    }

    $ssl_paths = profile::pki::get_cert('discovery', $proxy_domain, {
        'owner'           => 'root',
        'group'           => 'www-data',
        'notify_services' => ['nginx'],
    })
    $ssl_key   = $ssl_paths['key']
    $ssl_chain = $ssl_paths['chained']
    nginx::site { $proxy_domain:
        content => template('profile/hcaptcha/proxy.nginx.conf.erb'),
        notify  => Service['nginx'],
    }

    $subdomains.each |$prefix, $target| {
        $subdomain = "${prefix}.${proxy_domain}"
        $subdomain_ssl_paths = profile::pki::get_cert('discovery', $subdomain, {
            'owner'           => 'root',
            'group'           => 'www-data',
            'notify_services' => ['nginx'],
        })
        $subdomain_ssl_key = $subdomain_ssl_paths['key']
        $subdomain_ssl_chain = $subdomain_ssl_paths['chained']
        nginx::site { $subdomain:
            content => template('profile/hcaptcha/subdomain.nginx.conf.erb'),
            notify  => Service['nginx'],
        }
    }

    # TODO logging to logstash

    profile::auto_restarts::service { 'nginx': }
}
