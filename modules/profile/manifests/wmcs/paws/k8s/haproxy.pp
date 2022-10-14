# SPDX-License-Identifier: Apache-2.0
class profile::wmcs::paws::k8s::haproxy (
    Array[
        Variant[
            Stdlib::Fqdn,
            Struct[{
                host => Stdlib::Fqdn,
                port => Optional[Stdlib::Port],
            }]
        ]
    ]                   $ingress_nodes          = lookup('profile::wmcs::paws::ingress_nodes',         {default_value => ['localhost']}),
    Stdlib::Port        $ingress_backend_port   = lookup('profile::wmcs::paws::ingress_backend_port',  {default_value => 30000}),
    Stdlib::Port        $ingress_bind_tls_port  = lookup('profile::wmcs::paws::ingress_bind_tls_port', {default_value => 443}),
    Stdlib::Port        $ingress_bind_http_port = lookup('profile::wmcs::paws::ingress_bind_http_port',{default_value => 80}),
    Array[Stdlib::Fqdn] $control_nodes          = lookup('profile::wmcs::paws::control_nodes',         {default_value => ['localhost']}),
    Stdlib::Port        $api_port               = lookup('profile::wmcs::paws::apiserver_port',        {default_value => 6443}),
    Array[Stdlib::Fqdn] $prometheus_nodes       = lookup('profile::wmcs::paws::prometheus_nodes',      {default_value => []}),
    Array[Stdlib::Fqdn] $keepalived_vips        = lookup('profile::wmcs::paws::keepalived::vips',      {default_value => ['localhost']}),
    Array[Stdlib::Fqdn] $keepalived_peers       = lookup('profile::wmcs::paws::keepalived::peers',     {default_value => ['localhost']}),
    String              $keepalived_password    = lookup('profile::wmcs::paws::keepalived::password',  {default_value => 'notarealpassword'}),
    Array[String]       $ip_blocks              = lookup('profile::wmcs::paws::ip_blocks',             {default_value => []}),
) {
    class { 'haproxy::cloud::base': }

    $cert_name = 'paws'
    acme_chief::cert { $cert_name:
        puppet_rsc => Service['haproxy'],
    }
    $cert_file = "/etc/acmecerts/${cert_name}/live/ec-prime256v1.chained.crt.key"

    file { '/etc/haproxy/conf.d/k8s-api-servers.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/wmcs/paws/k8s/haproxy/k8s-api-servers.cfg.erb'),
        notify  => Service['haproxy'],
    }

    file { '/etc/haproxy/conf.d/k8s-ingress.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/wmcs/paws/k8s/haproxy/k8s-ingress.cfg.erb'),
        notify  => Service['haproxy'],
    }

    file { '/etc/haproxy/blocklisted.ips':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/wmcs/paws/k8s/haproxy/blocklist.erb'),
        notify  => Service['haproxy'],
    }

    class { 'prometheus::haproxy_exporter': }

    class { 'keepalived':
        auth_pass => $keepalived_password,
        peers     => delete($keepalived_peers, $::fqdn),
        vips      => $keepalived_vips.map |$host| { ipresolve($host, 4) }
    }
}
