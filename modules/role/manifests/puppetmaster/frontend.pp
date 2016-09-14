# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::frontend {

    include role::backup::host
    backup::set { 'var-lib-puppet-ssl': }
    backup::set { 'var-lib-puppet-volatile': }

    system::role { 'puppetmaster':
        description => 'Puppetmaster frontend'
    }

    # Puppet frontends are git masters at least for their datacenter

    $ca_server = hiera('puppetmaster::ca_server', 'palladium.eqiad.wmnet')

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


    class { '::role::puppetmaster::common':
        base_config => {
            'ca'        => $ca,
            'ca_server' => $ca_server,
        }
    }


    class { '::puppetmaster':
        bind_address  => '*',
        server_type   => 'frontend',
        is_git_master => true,
        workers       => $workers,
        config        => $::role::puppetmaster::common::config,
    }

    # On all the frontends we should respond
    # to the FQDN, as it's used in the SRV records
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

    ferm::service { 'puppetmaster-backend':
        proto => 'tcp',
        port  => 8141,
    }

    ferm::service { 'puppetmaster-frontend':
        proto => 'tcp',
        port  => 8140,
    }

    $puppetmaster_frontend_ferm = join(keys(hiera('puppetmaster::servers')), ' ')
    ferm::service { 'ssh_puppet_merge':
        proto  => 'tcp',
        port   => '22',
        srange => "@resolve((${puppetmaster_frontend_ferm}))"
    }

    ferm::service { 'rsync_puppet_frontends':
        proto  => 'tcp',
        port   => '873',
        srange => "@resolve((${puppetmaster_frontend_ferm}))"
    }
}
