# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::labs::puppetmaster::frontend() {
    system::role { 'puppetmaster':
        description => 'Puppetmaster frontend'
    }

    include network::constants
    $labs_metal = hiera('labs_baremetal_servers', [])
    $novaconfig = hiera_hash('novaconfig', {})
    $labs_instance_range = $novaconfig['fixed_range']
    $horizon_host = hiera('labs_horizon_host')
    $horizon_host_ip = ipresolve(hiera('labs_horizon_host'), 4)
    $designate_host_ip = ipresolve(hiera('labs_designate_hostname'), 4)

    # Only allow puppet access from the instances
    $allow_from = flatten([$labs_instance_range, '208.80.154.14', '208.80.155.119', '208.80.153.74', $horizon_host_ip, $labs_metal])

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

    $fwrules = {
        puppetmaster => {
            rule => "saddr (${labs_vms} ${labs_metal} ${monitoring} ${horizon_host_ip}) proto tcp dport 8140 ACCEPT;",
        },
        puppetbackend => {
            rule => "saddr (${horizon_host_ip} ${designate_host_ip}) proto tcp dport 8101 ACCEPT;",
        },
        puppetbackendgetter => {
            rule => "saddr (${labs_vms} ${labs_metal} ${monitoring} ${horizon_host_ip}) proto tcp dport 8100 ACCEPT;",
        },
    }
    create_resources (ferm::rule, $fwrules)
}
