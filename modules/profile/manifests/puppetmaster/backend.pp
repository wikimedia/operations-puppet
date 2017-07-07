# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class profile::puppetmaster::backend(
    $secure_private = true,
    $config,
) {
    system::role { 'puppetmaster':
        description => 'Puppetmaster backend'
    }

    $ca_server = hiera('puppetmaster::ca_server', 'puppetmaster1001.eqiad.wmnet')

    common_config => {
        'ca'              => $ca,
        'ca_server'       => $ca_server,
        'stringify_facts' => false,
    }
    base_config = merge($config, $common_config)

    class { '::profile::puppetmaster::common':
        base_config => $base_config,
    }

    class { '::puppetmaster':
        server_type    => 'backend',
        config         => $::profile::puppetmaster::common::config,
        secure_private => $secure_private,
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
