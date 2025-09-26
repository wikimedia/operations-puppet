# @param web_backend_conn_limit Maximum concurrent connections per single backend server
# @param web_tool_connection_limit Maximum number of in-flight requests a single tool can have
class profile::toolforge::k8s::haproxy (
    Array[Stdlib::Fqdn] $ingress_nodes             = lookup('profile::toolforge::k8s::ingress_nodes',                      {default_value => ['localhost']}),
    Stdlib::Port        $ingress_backend_port      = lookup('profile::toolforge::k8s::ingress_backend_port',               {default_value => 30002}),
    Array[Stdlib::Fqdn] $control_nodes             = lookup('profile::toolforge::k8s::control_nodes',                      {default_value => ['localhost']}),
    Stdlib::Port        $api_port                  = lookup('profile::toolforge::k8s::apiserver_port',                     {default_value => 6443}),
    Stdlib::Port        $api_gateway_port          = lookup('profile::toolforge::k8s::haproxy::api_gateway_port',          {default_value => 30003}),
    Array[Stdlib::Host] $keepalived_vips           = lookup('profile::toolforge::k8s::haproxy::keepalived_vips',           {default_value => []}),
    Array[Stdlib::Fqdn] $keepalived_peers          = lookup('profile::toolforge::k8s::haproxy::keepalived_peers',          {default_value => ['localhost']}),
    String              $keepalived_password       = lookup('profile::toolforge::k8s::haproxy::keepalived_password',       {default_value => 'notarealpassword'}),
    Stdlib::Fqdn        $web_domain                = lookup('profile::toolforge::web_domain',                              {default_value => 'toolforge.org'}),
    Integer             $web_backend_conn_limit    = lookup('profile::toolforge::web_backend_conn_limit',                  {default_value => 2000}),
    Integer             $web_tool_connection_limit = lookup('profile::toolforge::k8s::haproxy::web_tool_connection_limit', {default_value => 250}),
    String[1]           $acme_certname             = lookup('profile::toolforge::k8s::haproxy::acme_certname',             {default_value => 'toolforge'}),
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
            vips      => wmflib::hosts2ips($keepalived_vips),
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

    file { '/etc/haproxy/errors':
        ensure => directory,
    }

    mediawiki::errorpage {
        default:
            # TODO: these images are served from the front Nginx proxy,
            # migrate them somewhere else (tools-static? object storage?)
            favicon     => '/.error/favicon.ico',
            pagetitle   => 'Wikimedia Toolforge Error',
            logo_src    => '/.error/toolforge-logo.png',
            logo_srcset => '/.error/toolforge-logo-2x.png 2x',
            logo_width  => 120,
            logo_height => 120,
            logo_alt    => 'Wikimedia Toolforge',
            logo_link   => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge',
            footer      => "<p>${facts['networking']['fqdn']}</p>",
            owner       => 'www-data',
            group       => 'www-data',
            mode        => '0444',
            notify      => Service['haproxy'];

        '/etc/haproxy/errors/errorpage.html':
            content => '<p>Our servers are currently experiencing a technical problem. This is probably temporary and should be fixed soon. Please try again later.</p>';
        '/etc/haproxy/errors/overloaded.html':
            content => '<p>The tool you are trying to access is currently receiving more traffic than it can handle.</p>';
    }
}
