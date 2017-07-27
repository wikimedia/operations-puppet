# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class profile::puppetmaster::frontend(
    $config = hiera('profile::puppetmaster::frontend::config', {}),
    $secure_private = hiera('profile::puppetmaster::frontend::config', true),
    $web_hostname = hiera('profile::puppetmaster::frontend::web_hostname', 'puppet'),
    $prevent_cherrypicks = hiera('profile::puppetmaster::frontend::prevent_cherry-picks', true),
    $allow_from = [
      '*.wikimedia.org',
      '*.eqiad.wmnet',
      '*.ulsfo.wmnet',
      '*.esams.wmnet',
      '*.codfw.wmnet'],
) {
    backup::set { 'var-lib-puppet-ssl': }
    backup::set { 'var-lib-puppet-volatile': }

    # Puppet frontends are git masters at least for their datacenter

    $ca_server = hiera('puppetmaster::ca_server', 'puppetmaster1001.eqiad.wmnet')

    if $ca_server == $::fqdn {
        $ca = true
        $cron = 'absent'
    } else {
        $ca = false
        $cron = 'present'
    }

    ## Configuration
    $servers = hiera('puppetmaster::servers', {})
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
        bind_address        => '*',
        server_type         => 'frontend',
        is_git_master       => true,
        workers             => $workers,
        config              => $::profile::puppetmaster::common::config,
        secure_private      => $secure_private,
        prevent_cherrypicks => $prevent_cherrypicks,
        allow_from          => $allow_from,
    }

    # Main site to respond to
    ::puppetmaster::web_frontend { $web_hostname:
        master       => $ca_server,
        workers      => $workers,
        bind_address => $::puppetmaster::bind_address,
        priority     => 40,
    }

    # On all the puppetmasters, we should respond
    # to the FQDN too, in case we point them explicitly
    ::puppetmaster::web_frontend { $::fqdn:
        master       => $ca_server,
        workers      => $workers,
        bind_address => $::puppetmaster::bind_address,
        priority     => 50,
    }

    # Run the rsync servers on all puppetmaster frontends, and activate
    # crons syncing from the master
    class { '::puppetmaster::rsync':
        server      => $ca_server,
        cron_ensure => $cron,
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
