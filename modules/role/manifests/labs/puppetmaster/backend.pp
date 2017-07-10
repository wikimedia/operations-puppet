# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::labs::puppetmaster::backend {
    system::role { 'puppetmaster':
        description => 'Puppetmaster backend'
    }

    include ::standard
    include ::base::firewall

    include ::profile::puppetmaster::labsenc
    include ::profile::puppetmaster::labsencapi

    $config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => true,
    }

    class { '::profile::puppetmaster::backend':
        config         => $config,
        secure_private => false,
    }

    require ::profile::conftool::client
}
