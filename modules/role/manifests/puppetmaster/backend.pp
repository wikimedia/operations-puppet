# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::puppetmaster::backend {
    include ::base::firewall

    system::role { 'puppetmaster':
        description => 'Puppetmaster backend'
    }

    $ca_server = hiera('puppetmaster::ca_server', 'puppetmaster1001.eqiad.wmnet')

    class { '::role::puppetmaster::common':
        base_config => {
            'ca'        => false,
            'ca_server' => $ca_server,
        }
    }

    class { '::puppetmaster':
        server_type => 'backend',
        config      => $::role::puppetmaster::common::config
    }

    $puppetmaster_frontend_ferm = join(keys(hiera('puppetmaster::servers')), ' ')
    ferm::service { 'ssh_puppet_merge':
        proto  => 'tcp',
        port   => '22',
        srange => "(@resolve((${puppetmaster_frontend_ferm})) @resolve((${puppetmaster_frontend_ferm}), AAAA))"
    }
    ferm::service { 'puppetmaster-backend':
        proto  => 'tcp',
        port   => 8141,
        srange => "(@resolve((${puppetmaster_frontend_ferm})) @resolve((${puppetmaster_frontend_ferm}), AAAA))"
    }
    require ::profile::conftool::client
}
