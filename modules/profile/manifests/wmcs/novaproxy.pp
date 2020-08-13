class profile::wmcs::novaproxy(
    Array[Stdlib::Fqdn] $all_proxies      = lookup('profile::wmcs::novaproxy::all_proxies',  {default_value => ['localhost']}),
    Stdlib::Fqdn        $active_proxy     = lookup('profile::wmcs::novaproxy::active_proxy', {default_value => 'localhost'}),
    Boolean             $use_ssl          = lookup('profile::wmcs::novaproxy::use_ssl',      {default_value => true}),
    String              $acme_certname    = lookup('profile::wmcs::novaproxy::use_ssl',      {default_value => ''}),
    Array[Stdlib::Ipv4] $banned_ips       = lookup('profile::wmcs::novaproxy::banned_ips',   {default_value => []}),
    String              $block_ua_re      = lookup('profile::wmcs::novaproxy::block_ua_re',  {default_value => ''}),
    String              $block_ref_re     = lookup('profile::wmcs::novaproxy::block_ref_re', {default_value => ''}),
    Array[Stdlib::Fqdn] $xff_fqdns        = lookup('profile::wmcs::novaproxy::xff_fqdns',    {default_value => []}),
    Boolean             $use_wmflabs_root = lookup('profile::wmcs::novaproxy::use_ssl',      {default_value => true}),
    Boolean             $do_https     = lookup('profile::wmcs::novaproxy::do_https',   {default_value => true}),
) {
    $proxy_nodes = join($all_proxies, ' ')
    # Open up redis to all proxies!
    ferm::service { 'redis-replication':
        proto  => 'tcp',
        port   => '6379',
        srange => "@resolve((${proxy_nodes}))",
    }

    ferm::service { 'http':
        proto => 'tcp',
        port  => '80',
        desc  => 'HTTP webserver for the entire world',
    }

    ferm::service { 'https':
        proto => 'tcp',
        port  => '443',
        desc  => 'HTTPS webserver for the entire world',
    }

    ferm::service { 'dynamicproxy-api-http':
        port  => '5668',
        proto => 'tcp',
        desc  => 'API for adding / removing proxies from dynamicproxy domainproxy'
    }

    ferm::service { 'dynamicproxy-api-http-readonly':
        port  => '5669',
        proto => 'tcp',
        desc  => 'read-only API for viewing proxies from dynamicproxy domainproxy'
    }

    if $::hostname != $active_proxy {
        $redis_replication = {
            "${::hostname}" => $active_proxy
        }
    } else {
        $redis_replication = undef
    }

    if $acme_certname != '' {
        acme_chief::cert { $acme_certname:
            puppet_rsc => Exec['nginx-reload'],
        }
        $ssl_settings  = ssl_ciphersuite('nginx', 'compat')
        $ssl_certificate_name = $acme_certname
        $use_acme_chief = true
    } elsif $use_ssl {
        sslcert::certificate { 'star.wmflabs.org':
            skip_private => true,
            before       => Class['dynamicproxy'],
        }
        $ssl_settings  = ssl_ciphersuite('nginx', 'compat')
        $ssl_certificate_name = 'star.wmflabs.org'
        $use_acme_chief = false
    } else {
        $ssl_settings  = undef
        $ssl_certificate_name = false
        $use_acme_chief = false
    }

    class { '::dynamicproxy':
        ssl_certificate_name     => $ssl_certificate_name,
        ssl_settings             => $ssl_settings,
        xff_fqdns                => $xff_fqdns,
        luahandler               => 'domainproxy',
        redis_replication        => $redis_replication,
        banned_ips               => $banned_ips,
        blocked_user_agent_regex => $block_ua_re,
        blocked_referer_regex    => $block_ref_re,
        https_upgrade            => $do_https,
        use_acme_chief           => $use_acme_chief,
    }

    class { '::dynamicproxy::api': }

    if $use_wmflabs_root {
        nginx::site { 'wmflabs.org':
            content => template('profile/wmcs/novaproxy-wmflabs.org.conf')
        }
    }
}

