# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::backend {
    include base::firewall

    system::role { 'puppetmaster':
        description => 'Puppetmaster backend'
    }

    $ca_server = hiera('puppetmaster::ca_server', 'palladium.eqiad.wmnet')

    class { '::role::puppetmaster::common':
        base_config => {
            # lint:ignore:quoted_booleans
            # Not a simple boolean, this must be quoted.
            'ca'        => 'false',
            # lint:endignore
            'ca_server' => $ca_server,
        }
    }

    
    class { '::puppetmaster':
        server_type => 'backend',
        config      => $::role::puppetmaster::common::config
    }

    ferm::service { 'puppetmaster-backend':
        proto => 'tcp',
        port  => 8141,
    }

    $puppetmaster_frontend_ferm = join(keys(hiera('puppetmaster::servers')), ' ')
    ferm::service { 'ssh_puppet_merge':
        proto  => 'tcp',
        port   => '22',
        srange => "@resolve((${puppetmaster_frontend_ferm}))"
    }
}
