# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::labs::puppetmaster::frontend() {
    system::role { 'puppetmaster':
        description => 'Puppetmaster frontend'
    }

    include ::base::firewall

    include ::profile::backup::host
    include ::profile::puppetmaster::labsenc
    include ::profile::puppetmaster::labsencapi

    $config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => true,
    }

    class { '::profile::puppetmaster::frontend':
        config         => $config,
        secure_private => false,
    }

    include ::profile::conftool::client
    include ::profile::conftool::master

    include puppetmaster::labsrootpass

    # config-master.wikimedia.org
    include ::profile::configmaster
    include ::profile::discovery::client
}
