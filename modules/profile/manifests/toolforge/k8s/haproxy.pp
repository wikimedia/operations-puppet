class profile::toolforge::k8s::haproxy (
    Array[Stdlib::Fqdn] $ingress_nodes        = lookup('profile::toolforge::k8s::ingress_nodes',                {default_value => ['localhost']}),
    Stdlib::Port        $ingress_backend_port = lookup('profile::toolforge::k8s::ingress_backend_port',         {default_value => 30002}),
    Array[Stdlib::Fqdn] $control_nodes        = lookup('profile::toolforge::k8s::control_nodes',                {default_value => ['localhost']}),
    Stdlib::Port        $api_port             = lookup('profile::toolforge::k8s::apiserver_port',               {default_value => 6443}),
    Stdlib::Port        $api_gateway_port     = lookup('profile::toolforge::k8s::haproxy::api_gateway_port',    {default_value => 30003}),
    Array[Stdlib::Fqdn] $keepalived_vips      = lookup('profile::toolforge::k8s::haproxy::keepalived_vips',     {default_value => []}),
    Array[Stdlib::Fqdn] $keepalived_peers     = lookup('profile::toolforge::k8s::haproxy::keepalived_peers',    {default_value => ['localhost']}),
    String              $keepalived_password  = lookup('profile::toolforge::k8s::haproxy::keepalived_password', {default_value => 'notarealpassword'}),
    Stdlib::Fqdn        $web_domain           = lookup('profile::toolforge::web_domain',                        {default_value => 'toolforge.org'}),
    String[1]           $acme_certname        = lookup('profile::toolforge::k8s::haproxy::acme_certname',       {default_value => 'toolforge'}),
) {
    class { 'haproxy::cloud::base': }

    acme_chief::cert { $acme_certname:
        puppet_svc => 'haproxy',
    }

    file { '/etc/haproxy/conf.d/k8s-api-servers.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/k8s/haproxy/k8s-api-servers.cfg.erb'),
        notify  => Service['haproxy'],
    }

    file { '/etc/haproxy/conf.d/k8s-ingress.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/k8s/haproxy/k8s-ingress.cfg.erb'),
        notify  => Service['haproxy'],
    }

    file { '/etc/haproxy/conf.d/k8s-ingress-api-gateway.cfg':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('profile/toolforge/k8s/haproxy/k8s-ingress-api-gateway.cfg.erb'),
        notify  => Service['haproxy'],
    }

    class { 'prometheus::haproxy_exporter': }

    if !$keepalived_vips.empty() and $facts['networking']['fqdn'] in $keepalived_peers {
        class { 'keepalived::failover':
            auth_pass => $keepalived_password,
            peers     => delete($keepalived_peers, $facts['networking']['fqdn']),
            vips      => $keepalived_vips.map |$host| { dnsquery::lookup($host, true) }.flatten,
        }
    }

    prometheus::blackbox::check::http {
        default:
            port                => 443,
            ip_families         => ['ip4'],
            prometheus_instance => 'tools',
            team                => 'wmcs',
            severity            => 'warning',
            probe_runbook       => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge/Admin/Runbooks/k8s-haproxy';

        # well-known-to-exist web service
        "admin.${web_domain}":
            path               => '/healthz',
            body_regex_matches => ['OK'];

        # monitor the 404 handler
        # creation on this tool has been blocked by the title blacklist
        "this-tool-does-not-exist.${web_domain}":
            timeout            => '15s',
            body_regex_matches => ['The URL you have requested'],
            status_matches     => [404];

        "api.svc.${web_domain}":
            path               => '/healthz',
            body_regex_matches => ['ok'],
            # making it explicit
            status_matches     => [200];
    }
}
