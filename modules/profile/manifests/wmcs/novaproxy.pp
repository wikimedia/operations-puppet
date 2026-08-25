# @param rate_limit_requests Number of average requests per second a single IP address can perform
# @param rate_limit_burst_time Number of seconds over which the per-IP rate limit is counted
class profile::wmcs::novaproxy (
    Array[Stdlib::Fqdn]               $all_proxies                   = lookup('profile::wmcs::novaproxy::all_proxies',    {default_value => ['localhost']}),
    Stdlib::Fqdn                      $active_proxy                  = lookup('profile::wmcs::novaproxy::active_proxy',   {default_value => 'localhost'}),
    String[1]                         $acme_certname                 = lookup('profile::wmcs::novaproxy::acme_certname'),
    String                            $block_ua_re                   = lookup('profile::wmcs::novaproxy::block_ua_re',    {default_value => ''}),
    String                            $block_ref_re                  = lookup('profile::wmcs::novaproxy::block_ref_re',   {default_value => ''}),
    Array[Stdlib::Fqdn]               $xff_fqdns                     = lookup('profile::wmcs::novaproxy::xff_fqdns',      {default_value => []}),
    Array[Stdlib::IP::Address::V4]    $banned_ips                    = lookup('profile::wmcs::novaproxy::banned_ips',     {default_value => []}),
    Boolean                           $api_readonly                  = lookup('profile::wmcs::novaproxy::api_readonly',   {default_value => false}),
    Stdlib::IP::Address::V4::Nosubnet $proxy_dns_ipv4                = lookup('profile::wmcs::novaproxy::proxy_dns_ipv4'),
    Stdlib::IP::Address::V6::Nosubnet $proxy_dns_ipv6                = lookup('profile::wmcs::novaproxy::proxy_dns_ipv6'),
    Hash[String, Dynamicproxy::Zone]  $supported_zones               = lookup('profile::wmcs::novaproxy::supported_zones'),
    Integer                           $rate_limit_requests           = lookup('profile::wmcs::novaproxy::rate_limit_requests', {default_value => 100}),
    Integer                           $rate_limit_burst_time         = lookup('profile::wmcs::novaproxy::rate_limit_burst_time', {default_value => 5}),
    Enum['http', 'https']             $keystone_api_protocol         = lookup('profile::openstack::base::keystone::auth_protocol'),
    Stdlib::Port                      $keystone_api_port             = lookup('profile::openstack::base::keystone::public_port'),
    # I don't want to add per-deployment profiles, so this is duplicated instead of using profile::openstack::$DEPLOYMENT::keystone_api_fqdn
    Stdlib::Fqdn                      $keystone_api_fqdn             = lookup('profile::wmcs::novaproxy::keystone_api_fqdn'),
    String                            $dns_updater_username          = lookup('profile::wmcs::novaproxy::dns_updater_username'),
    String                            $dns_updater_project           = lookup('profile::wmcs::novaproxy::dns_updater_project'),
    String                            $dns_updater_password          = lookup('profile::wmcs::novaproxy::dns_updater_password'),
    String                            $token_validator_username      = lookup('profile::wmcs::novaproxy::token_validator_username'),
    String                            $token_validator_project       = lookup('profile::wmcs::novaproxy::token_validator_project'),
    String                            $token_validator_password      = lookup('profile::wmcs::novaproxy::token_validator_password'),
    Stdlib::Host                      $mariadb_host                  = lookup('profile::wmcs::novaproxy::mariadb_host'),
    String[1]                         $mariadb_db                    = lookup('profile::wmcs::novaproxy::mariadb_db'),
    String[1]                         $mariadb_username              = lookup('profile::wmcs::novaproxy::mariadb_username'),
    String[1]                         $mariadb_password              = lookup('profile::wmcs::novaproxy::mariadb_password'),
    Array[Stdlib::IP::Address]        $keepalived_vips               = lookup('profile::wmcs::novaproxy::keepalived_vips',     {default_value => []}),
    Optional[Array[Stdlib::Fqdn]]     $keepalived_peers              = lookup('profile::wmcs::novaproxy::keepalived_peers',    {default_value => undef}),
    String[1]                         $keepalived_password           = lookup('profile::wmcs::novaproxy::keepalived_password', {default_value => 'notarealpassword'}),
    Integer                           $global_connection_limit       = lookup('profile::wmcs::novaproxy::global_connection_limit', {default_value => 98304}),
    Integer                           $frontend_conn_limit           = lookup('profile::wmcs::novaproxy::frontend_conn_limit', {default_value => 65536}),
    Integer                           $web_client_timeout            = lookup('profile::wmcs::novaproxy::web_client_timeout', {default_value => 90}),
    Integer                           $http_redirect_conn_limit      = lookup('profile::wmcs::novaproxy::http_redirect_conn_limit', {default_value => 1024}),
    Array[Stdlib::Host]               $metricsinfra_prometheus_nodes = lookup('metricsinfra_prometheus_nodes'),
    Stdlib::Host                      $acmechief_host                = lookup('acmechief_host'),
) {
    $zone_acme_certs = $supported_zones
        .values
        .map |Dynamicproxy::Zone $zone| { $zone['acmechief_cert'] }
    $acme_certs = [$zone_acme_certs, $acme_certname].flatten.unique

    acme_chief::cert { $acme_certs:
        puppet_svc => 'haproxy',
    }

    firewall::service { 'http':
        proto => 'tcp',
        port  => 80,
        desc  => 'HTTP webserver for the entire world',
    }

    firewall::service { 'https':
        proto => 'tcp',
        port  => 443,
        desc  => 'HTTPS webserver for the entire world',
    }

    firewall::service { 'dynamicproxy-api-http':
        port  => 5668,
        proto => 'tcp',
        desc  => 'Web proxy management API',
    }

    include profile::mariadb::packages_client
    mariadb::config::client { 'webproxy':
        path => '/etc/my.cnf',
        host => $mariadb_host,
        port => 3306,
        user => $mariadb_username,
        pass => $mariadb_password,
        db   => $mariadb_db,
    }

    class { 'haproxy':
        config_content   => template('profile/wmcs/novaproxy/haproxy.cfg.erb'),
        logging          => true,
        logrotate_config => 'puppet:///modules/profile/wmcs/novaproxy/haproxy.logrotate',
        # No Icinga support here
        monitor          => false,
    }

    systemd::override { 'haproxy-novaproxy':
        unit    => 'haproxy',
        source  => 'puppet:///modules/profile/wmcs/novaproxy/haproxy.override.service',
        restart => true,
    }

    include profile::haproxy::resolver

    # ensure correct ordering when porting sites to haproxy
    Exec['nginx-reload'] -> Service['haproxy']

    $prometheus_ips = $metricsinfra_prometheus_nodes.wmflib::hosts2ips()
    haproxy::site { 'stats':
        content => template('profile/wmcs/novaproxy/stats.cfg.erb'),
    }

    class { '::dynamicproxy': }
    class { '::dynamicproxy::api':
        acme_certname            => $acme_certname,
        proxy_dns_ipv4           => $proxy_dns_ipv4,
        proxy_dns_ipv6           => $proxy_dns_ipv6,
        supported_zones          => $supported_zones,
        read_only                => $api_readonly,
        keystone_api_url         => "${keystone_api_protocol}://${keystone_api_fqdn}:${keystone_api_port}",
        dns_updater_username     => $dns_updater_username,
        dns_updater_password     => $dns_updater_password,
        dns_updater_project      => $dns_updater_project,
        token_validator_username => $token_validator_username,
        token_validator_password => $token_validator_password,
        token_validator_project  => $token_validator_project,
        mariadb_host             => $mariadb_host,
        mariadb_db               => $mariadb_db,
        mariadb_username         => $mariadb_username,
        mariadb_password         => $mariadb_password,
    }

    file { '/etc/haproxy/cert-map.txt':
        ensure  => file,
        content => template('profile/wmcs/novaproxy/cert-map.txt.erb'),
        notify  => Service['haproxy'],
    }

    file { '/etc/haproxy/xff-fqdns.txt':
        ensure  => file,
        content => "${xff_fqdns.join("\n")}\n",
        notify  => Service['haproxy'],
    }

    file { '/etc/haproxy/banned-ips.txt':
        ensure  => file,
        content => "${banned_ips.join("\n")}\n",
        notify  => Service['haproxy'],
    }

    file { '/etc/haproxy/novaproxy.map':
        ensure  => file,
        content => '',
        replace => false,
        notify  => Service['haproxy'],
    }

    haproxy::site { 'novaproxy':
        content => template('profile/wmcs/novaproxy/novaproxy.cfg.erb'),
    }

    file { '/usr/local/sbin/novaproxy-update-map':
        ensure => file,
        source => 'puppet:///modules/profile/wmcs/novaproxy/novaproxy-update-map.sh',
        mode   => '0544',
    }

    systemd::timer::job { 'novaproxy-update-map':
        ensure      => present,
        user        => 'root',
        description => 'Update Novaproxy backend mapping from database',
        command     => '/usr/local/sbin/novaproxy-update-map',
        interval    => {'start' => 'OnCalendar', 'interval' => 'minutely'},
        require     => File['/etc/haproxy/novaproxy.map'],
    }

    haproxy::site { 'http-redirect':
        content => template('profile/wmcs/novaproxy/http-redirect.cfg.erb'),
    }

    # Disable the nchan module, we don't use pub/sub on nginx
    file { '/etc/nginx/modules-enabled/50-mod-nchan.conf':
        ensure => 'absent',
        notify => Service['nginx'],
    }

    class { 'prometheus::nginx_exporter': }

    $_keepalived_peers = $keepalived_peers.lest || { $all_proxies }
    if !$keepalived_vips.empty() and !$_keepalived_peers.empty() {
        $is_primary = $facts['networking']['hostname'] == $active_proxy
        # Ensure the primary server (where we would prefer to get API writes)
        # gets priority when it is online
        $priority_modifier = $is_primary ? {
            true    => 100,
            default => 0,
        }

        class { 'keepalived::failover':
            auth_pass => $keepalived_password,
            peers     => $_keepalived_peers - $::facts['networking']['fqdn'],
            vips      => $keepalived_vips,
            priority  => fqdn_rand(100) + $priority_modifier,
        }

        ferm::rule { 'keepalived-vrrp':
            rule   => "proto vrrp saddr ${ferm::join_hosts($_keepalived_peers)} ACCEPT;",
        }
    }
}

