# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class profile::puppetmaster::frontend(
    Hash                $config                  = lookup('profile::puppetmaster::frontend::config'),
    Boolean             $secure_private          = lookup('profile::puppetmaster::frontend::secure_private'),
    String              $web_hostname            = lookup('profile::puppetmaster::frontend::web_hostname'),
    Boolean             $prevent_cherrypicks     = lookup('profile::puppetmaster::frontend::prevent_cherrypicks'),
    Stdlib::Host        $ca_server               = lookup('puppet_ca_server'),
    Stdlib::Filesource  $ca_source               = lookup('puppet_ca_source'),
    Boolean             $manage_ca_file          = lookup('manage_puppet_ca_file'),
    Array[String]       $allow_from              = lookup('profile::puppetmaster::frontend::allow_from'),
    String              $extra_auth_rules        = lookup('profile::puppetmaster::frontend::extra_auth_rules'),
    Array[Stdlib::Host] $canary_hosts            = lookup('profile::puppetmaster::frontend::canary_hosts'),
    Hash[String, Puppetmaster::Backends] $servers          = lookup('puppetmaster::servers'),
    Hash[Stdlib::Host, Stdlib::Host]     $locale_servers   = lookup('puppetmaster::locale_servers'),
    Enum['chain', 'leaf', 'none'] $ssl_ca_revocation_check = lookup('profile::puppetmaster::frontend::ssl_ca_revocation_check'),
    Optional[String[1]] $mcrouter_ca_secret      = lookup('profile::puppetmaster::frontend::mcrouter_ca_secret',
                                                          {'default_value' => undef}),
) {
    backup::set { 'var-lib-puppet-ssl': }
    backup::set { 'var-lib-puppet-volatile': }
    if $manage_ca_file {
        file{[$facts['puppet_config']['master']['localcacert'],
              "${facts['puppet_config']['master']['ssldir']}/ca/ca_crt.pem"]:
            ensure => file,
            owner  => 'puppet',
            group  => 'puppet',
            source => $ca_source,
        }
    }
    # Puppet frontends are git masters at least for their datacenter
    if $ca_server == $::fqdn {
        $ca = true
        $cron = 'absent'
    } else {
        $ca = false
        $cron = 'present'
    }

    if $ca {
        # Ensure cergen is present for managing TLS keys and
        # x509 certificates signed by the Puppet CA.
        class { 'cergen': }
        if $mcrouter_ca_secret {
            class { 'cergen::mcrouter_ca':
                ca_secret => $mcrouter_ca_secret,
            }
        }

        # Ship cassandra-ca-manager (precursor of cergen)
        class { 'cassandra::ca_manager': }
    }

    class { '::httpd':
        modules => ['proxy',
                    'proxy_http',
                    'proxy_balancer',
                    'passenger',
                    'rewrite',
                    'lbmethod_byrequests'],
    }

    require_package('libapache2-mod-passenger')

    class { 'puppetmaster::ca_server':
        master => $ca_server
    }

    $common_config = {
        'ca'              => $ca,
        'ca_server'       => $ca_server,
        'stringify_facts' => false,
    }

    $base_config = merge($config, $common_config)

    class { 'profile::puppetmaster::common':
        base_config => $base_config,
    }

    class { 'puppetmaster':
        bind_address        => '*',
        server_type         => 'frontend',
        is_git_master       => true,
        config              => $profile::puppetmaster::common::config,
        secure_private      => $secure_private,
        prevent_cherrypicks => $prevent_cherrypicks,
        allow_from          => $allow_from,
        extra_auth_rules    => $extra_auth_rules,
        ca_server           => $ca_server,
        ssl_verify_depth    => $profile::puppetmaster::common::ssl_verify_depth,
        servers             => $servers,
    }

    $workers = $servers[$facts['fqdn']]
    $locale_server = $locale_servers[$facts['fqdn']]
    # Main site to respond to
    puppetmaster::web_frontend { $web_hostname:
        master                  => $ca_server,
        workers                 => $workers,
        locale_server           => $locale_server,
        bind_address            => $::puppetmaster::bind_address,
        priority                => 40,
        ssl_ca_revocation_check => $ssl_ca_revocation_check,
        canary_hosts            => $canary_hosts,
        ssl_verify_depth        => $profile::puppetmaster::common::ssl_verify_depth,
    }

    # On all the puppetmasters, we should respond
    # to the FQDN too, in case we point them explicitly
    puppetmaster::web_frontend { $::fqdn:
        master                  => $ca_server,
        workers                 => $workers,
        locale_server           => $locale_server,
        bind_address            => $::puppetmaster::bind_address,
        priority                => 50,
        ssl_ca_revocation_check => $ssl_ca_revocation_check,
        canary_hosts            => $canary_hosts,
        ssl_verify_depth        => $profile::puppetmaster::common::ssl_verify_depth,
    }

    # Run the rsync servers on all puppetmaster frontends, and activate
    # crons syncing from the master
    class { '::puppetmaster::rsync':
        server      => $ca_server,
        cron_ensure => $cron,
        frontends   => keys($servers),
    }

    ferm::service { 'puppetmaster-frontend':
        proto => 'tcp',
        port  => 8140,
    }

    $puppetmaster_frontend_ferm = join(keys($servers), ' ')
    ferm::service { 'ssh_puppet_merge':
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${puppetmaster_frontend_ferm})) @resolve((${puppetmaster_frontend_ferm}), AAAA))"
    }

    ferm::service { 'rsync_puppet_frontends':
        proto  => 'tcp',
        port   => '873',
        srange => "(@resolve((${puppetmaster_frontend_ferm})) @resolve((${puppetmaster_frontend_ferm}), AAAA))"
    }
    ferm::service { 'puppetmaster-backend':
        proto  => 'tcp',
        port   => 8141,
        srange => "(@resolve((${puppetmaster_frontend_ferm})) @resolve((${puppetmaster_frontend_ferm}), AAAA))"
    }
}
