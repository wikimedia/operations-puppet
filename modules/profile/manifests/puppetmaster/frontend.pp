# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class profile::puppetmaster::frontend(
    $config = hiera('profile::puppetmaster::frontend::config', {}),
    # should $secure_priviate really get its config from the same
    # place as $config?
    $secure_private = hiera('profile::puppetmaster::frontend::config', true),
    $web_hostname = hiera('profile::puppetmaster::frontend::web_hostname', 'puppet'),
    $prevent_cherrypicks = hiera('profile::puppetmaster::frontend::prevent_cherrypicks', true),
    Stdlib::Host $ca_server = lookup('puppet_ca_server'),
    Hash[String, Puppetmaster::Backends] $servers = hiera('puppetmaster::servers', {}),
    Puppetmaster::Backends $test_servers = hiera('profile::puppetmaster::frontend::test_servers', []),
    $puppetdb_major_version = hiera('puppetdb_major_version', undef),
    $ssl_ca_revocation_check = hiera('profile::puppetmaster::frontend::ssl_ca_revocation_check', 'chain'),
    $allow_from = hiera('profile::puppetmaster::frontend::allow_from', [
      '*.wikimedia.org',
      '*.eqiad.wmnet',
      '*.ulsfo.wmnet',
      '*.esams.wmnet',
      '*.codfw.wmnet',
      '*.eqsin.wmnet']),
    $extra_auth_rules = '',
    $mcrouter_ca_secret = hiera('profile::puppetmaster::frontend::mcrouter_ca_secret'),
) {
    backup::set { 'var-lib-puppet-ssl': }
    backup::set { 'var-lib-puppet-volatile': }

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
        class { '::cergen': }
        if $mcrouter_ca_secret {
            class { '::cergen::mcrouter_ca':
                ca_secret => $mcrouter_ca_secret,
            }
        }
    }

    class { '::puppetmaster::ca_server':
        master => $ca_server
    }

    ## Configuration
    $workers = $servers[$::fqdn]

    $common_config = {
        'ca'              => $ca,
        'ca_server'       => $ca_server,
        'stringify_facts' => false,
    }

    $base_config = merge($config, $common_config)

    class { '::profile::puppetmaster::common':
        base_config => $base_config,
    }

    class { '::puppetmaster':
        bind_address           => '*',
        server_type            => 'frontend',
        is_git_master          => true,
        workers                => $workers,
        config                 => $::profile::puppetmaster::common::config,
        secure_private         => $secure_private,
        prevent_cherrypicks    => $prevent_cherrypicks,
        allow_from             => $allow_from,
        extra_auth_rules       => $extra_auth_rules,
        puppetdb_major_version => $puppetdb_major_version,
    }

    # Main site to respond to
    ::puppetmaster::web_frontend { $web_hostname:
        master                  => $ca_server,
        workers                 => $workers,
        bind_address            => $::puppetmaster::bind_address,
        priority                => 40,
        ssl_ca_revocation_check => $ssl_ca_revocation_check,
    }

    # On all the puppetmasters, we should respond
    # to the FQDN too, in case we point them explicitly
    ::puppetmaster::web_frontend { $::fqdn:
        master                  => $ca_server,
        workers                 => $workers,
        bind_address            => $::puppetmaster::bind_address,
        priority                => 50,
        ssl_ca_revocation_check => $ssl_ca_revocation_check,
    }

    # We want to be able to test new things on our infrastructure, having a separated
    # frontend for testing
    if $test_servers != [] {
        $alt_names = prefix(
            ['codfw.wmnet', 'eqiad.wmnet', 'eqsin.wmnet', 'esams.wmnet', 'ulsfo.wmnet'],
            'puppetmaster.test.'
        )

        ::puppetmaster::web_frontend { 'puppetmaster.test.eqiad.wmnet':
            master                  => $ca_server,
            workers                 => $test_servers,
            alt_names               => $alt_names,
            bind_address            => $::puppetmaster::bind_address,
            priority                => 60,
            ssl_ca_revocation_check => $ssl_ca_revocation_check,
        }
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
