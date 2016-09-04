# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::frontend {
    include passwords::puppet::database

    include role::backup::host
    backup::set { 'var-lib-puppet-ssl': }
    backup::set { 'var-lib-puppet-volatile': }

    system::role { 'puppetmaster':
        description => 'Puppetmaster frontend'
    }

    # Puppet frontends are git masters at least for their datacenter

    $ca_server = hiera('puppetmaster::ca_server', 'palladium.eqiad.wmnet')
    $ca = $ca_server ? {
        # lint:ignore:quoted_booleans
        $::fqdn => 'true',
        default => 'false',
        # lint:endignore
    }

    $servers = hiera('puppetmaster::servers', {})
    $workers = $servers[$::fqdn]

    class { '::puppetmaster':
        bind_address  => '*',
        server_type   => 'frontend',
        is_git_master => true,
        workers       => $workers,
        config        => {
            'ca'                => $ca,
            'ca_server'         => $ca_server,
            'storeconfigs'      => true, # Required by thin_storeconfigs on puppet 3.x
            'thin_storeconfigs' => true,
            'dbadapter'         => 'mysql',
            'dbuser'            => 'puppet',
            'dbpassword'        => $passwords::puppet::database::puppet_production_db_pass,
            'dbserver'          => 'm1-master.eqiad.wmnet',
        }
    }

    # On the primary frontend, we keep the old vhost
    # for compatibility
    if $ca_server == $::fqdn {
        ::puppetmaster::web_frontend { 'puppet':
            master       => $ca_server,
            workers      => $workers,
            bind_address => $::puppetmaster::bind_address,
            priority     => 40,
        }
    }

    # On all the puppetmasters, we should respond
    # to the FQDN, as it's used in the SRV records
    ::puppetmaster::web_frontend { $::fqdn:
        master       => $ca_server,
        workers      => $workers,
        bind_address => $::puppetmaster::bind_address,
        priority     => 50,
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
}
