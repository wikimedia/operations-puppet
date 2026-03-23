# @param web_backend_conn_limit Maximum concurrent connections per single backend server
# @param web_tool_connection_limit Maximum number of in-flight requests a single tool can have
# @param rate_limit_requests Number of average requests per second a single IP address can perform
# @param rate_limit_burst_time Number of seconds over which the per-IP rate limit is counted
# @param disabled_hosts Hostnames that should return a generic 403 error instead of handling actual requests
class profile::toolforge::k8s::haproxy (
    Array[Stdlib::Fqdn]        $ingress_nodes                   = lookup('profile::toolforge::k8s::ingress_nodes',                            {default_value => ['localhost']}),
    Stdlib::Port               $ingress_backend_port            = lookup('profile::toolforge::k8s::ingress_backend_port',                     {default_value => 30002}),
    Array[Stdlib::Fqdn, 1]     $gateway_nodes                   = lookup('profile::toolforge::k8s::gateway_nodes',                            {default_value => []}),
    Stdlib::Port               $gateway_backend_port            = lookup('profile::toolforge::k8s::gateway_backend_port',                     {default_value => 30000}),
    Integer[0, 100]            $gateway_traffic_percentage      = lookup('profile::toolforge::k8s::gateway_traffic_percentage',               {default_value => 5}),
    Array[Stdlib::Fqdn]        $control_nodes                   = lookup('profile::toolforge::k8s::control_nodes',                            {default_value => ['localhost']}),
    Stdlib::Port               $api_port                        = lookup('profile::toolforge::k8s::apiserver_port',                           {default_value => 6443}),
    Stdlib::Port               $api_gateway_port                = lookup('profile::toolforge::k8s::haproxy::api_gateway_port',                {default_value => 30003}),
    Stdlib::Port               $infra_tracing_loki_gateway_port = lookup('profile::toolforge::k8s::haproxy::infra_tracing_loki_gateway_port', {default_value => 30004}),
    Array[Stdlib::Host]        $keepalived_vips                 = lookup('profile::toolforge::k8s::haproxy::keepalived_vips',                 {default_value => []}),
    Array[Stdlib::Fqdn]        $keepalived_peers                = lookup('profile::toolforge::k8s::haproxy::keepalived_peers',                {default_value => ['localhost']}),
    String                     $keepalived_password             = lookup('profile::toolforge::k8s::haproxy::keepalived_password',             {default_value => 'notarealpassword'}),
    Stdlib::Fqdn               $web_domain                      = lookup('profile::toolforge::web_domain',                                    {default_value => 'toolforge.org'}),
    Integer                    $frontend_conn_limit             = lookup('profile::toolforge::k8s::haproxy::frontend_conn_limit',             {default_value => 65536}),
    Integer                    $web_backend_conn_limit          = lookup('profile::toolforge::web_backend_conn_limit',                        {default_value => 2000}),
    Integer                    $web_tool_connection_limit       = lookup('profile::toolforge::k8s::haproxy::web_tool_connection_limit',       {default_value => 250}),
    Integer                    $rate_limit_requests             = lookup('profile::toolforge::k8s::haproxy::rate_limit_requests',             {default_value => 50}),
    Integer                    $rate_limit_burst_time           = lookup('profile::toolforge::k8s::haproxy::rate_limit_burst_time',           {default_value => 5}),
    Array[Stdlib::Fqdn]        $disabled_hosts                  = lookup('profile::toolforge::k8s::haproxy::disabled_hosts',                  {default_value => []}),
    String[1]                  $acme_certname                   = lookup('profile::toolforge::k8s::haproxy::acme_certname',                   {default_value => 'toolforge'}),
    Stdlib::Fqdn               $static_domain             = lookup('profile::toolforge::static::static_domain',                   {default_value => 'tools-static.wmflabs.org'}),
    Optional[String[1]]        $blocked_user_agent_regex  = lookup('dynamicproxy::blocked_user_agent_regex',                      {default_value => undef}),
    Array[Stdlib::IP::Address] $banned_ips                = lookup('dynamicproxy::banned_ips',                                    {default_value => []}),
    Optional[String[1]]        $blocked_referer_regex     = lookup('dynamicproxy::blocked_referer_regex',                         {default_value => undef}),
    Array[Stdlib::Fqdn]        $prometheus_nodes          = lookup('prometheus_nodes'),
) {
    class { 'haproxy':
        template         => 'profile/toolforge/k8s/haproxy/haproxy.cfg.erb',
        logging          => true,
        logrotate_config => 'puppet:///modules/profile/toolforge/k8s/haproxy/haproxy.logrotate',
        # No Icinga support here
        monitor          => false,
    }

    include profile::haproxy::resolver

    file { '/etc/haproxy/banned-ips.txt':
        ensure  => file,
        content => "${banned_ips.join("\n")}\n",
        notify  => Service['haproxy'],
    }

    acme_chief::cert { $acme_certname:
        puppet_svc => 'haproxy',
    }

    $prometheus_ips = $prometheus_nodes.wmflib::hosts2ips()
    haproxy::site { 'stats':
        content => template('profile/toolforge/k8s/haproxy/stats.cfg.erb'),
    }

    haproxy::site { 'k8s-api-servers':
        content => template('profile/toolforge/k8s/haproxy/k8s-api-servers.cfg.erb'),
    }

    haproxy::site { 'k8s-ingress':
        content => template('profile/toolforge/k8s/haproxy/k8s-ingress.cfg.erb'),
    }

    haproxy::site { 'k8s-ingress-api-gateway':
        content => template('profile/toolforge/k8s/haproxy/k8s-ingress-api-gateway.cfg.erb'),
    }

    haproxy::site { 'k8s-ingress-infra-tracing-loki-gateway':
        content => template('profile/toolforge/k8s/haproxy/k8s-ingress-infra-tracing-loki-gateway.cfg.erb'),
    }

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

        "infra-tracing-loki.svc.${::wmcs_project}.${::wmcs_deployment}.wikimedia.cloud":
            path               => '/',
            port               => 30004,
            force_tls          => true,
            insecure_tls       => true,
            body_regex_matches => ['OK'],
            # making it explicit
            status_matches     => [200];
    }

    file { '/etc/haproxy/errors':
        ensure => directory,
    }

    file { '/etc/haproxy/errors/robots.txt':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/k8s/haproxy/ingress/robots.txt',
    }
    file { '/etc/haproxy/errors/favicon.ico':
        ensure => file,
        source => 'puppet:///modules/profile/toolforge/favicon.ico',
    }

    mediawiki::errorpage {
        default:
            favicon     => "https://${static_domain}/admin/errors/favicon.ico",
            pagetitle   => 'Wikimedia Toolforge Error',
            logo_src    => "https://${static_domain}/admin/errors/toolforge-logo.png",
            logo_srcset => "https://${static_domain}/admin/errors/toolforge-logo-2x.png 2x",
            logo_width  => 120,
            logo_height => 120,
            logo_alt    => 'Wikimedia Toolforge',
            logo_link   => 'https://wikitech.wikimedia.org/wiki/Portal:Toolforge',
            footer      => "<p>${facts['networking']['fqdn']}</p>",
            owner       => 'www-data',
            group       => 'www-data',
            mode        => '0444',
            notify      => Service['haproxy'];

        '/etc/haproxy/errors/banned.html':
            content => '<p>You have been banned from accessing Toolforge. Please see <a href="https://wikitech.wikimedia.org/wiki/Help:Toolforge/Banned">Help:Toolforge/Banned</a> for more information on why and on how to resolve this.</p>';
        '/etc/haproxy/errors/disabled.html':
            content => '<p>Access to this tool has been temporarily disabled. Please try again later.</p>';
        '/etc/haproxy/errors/errorpage.html':
            content => '<p>Our servers are currently experiencing a technical problem. This is probably temporary and should be fixed soon. Please try again later.</p>';
        '/etc/haproxy/errors/overloaded.html':
            content => @(EOF)
                <p>The tool you are trying to access is currently receiving more traffic than it can handle. Please try again later.</p>
                <p>If this issue persists, you may wish to notify the tool's maintainers about the error.</p>
                <h2>If you maintain this tool</h2>
                <p>Please see <a href="https://wikitech.wikimedia.org/wiki/Help:Toolforge/Web#%22receiving_more_traffic_than_it_can_handle%22">our documentation</a> for help fixing this issue.</p>
            | EOF
            ;
        '/etc/haproxy/errors/ratelimit.html':
            content => '<p>You are trying to access this service too fast.</p>';
    }
}
