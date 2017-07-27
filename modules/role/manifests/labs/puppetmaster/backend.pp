# vim: set tabstop=4 shiftwidth=4 softtabstop=4 expandtab textwidth=80 smarttab

class role::labs::puppetmaster::backend {
    system::role { 'puppetmaster':
        description => 'Puppetmaster backend'
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

    include ::standard
    include ::base::firewall

    include ::profile::puppetmaster::labsenc
    include ::profile::puppetmaster::labsencapi

    include puppetmaster::labsrootpass

    $config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => true,
    }

    class { '::profile::puppetmaster::backend':
        config         => $config,
        secure_private => false,
        allow_from     => $allow_from,
    }

    # Update git checkout.  This is done via a cron
    #  rather than via puppet_merge to increase isolation
    #  between these puppetmasters and the production ones.
    class { 'puppetmaster::gitsync':
        run_every_minutes => '1',
    }

    require ::profile::conftool::client

    $labs_vms = $novaconfig['fixed_range']
    $monitoring = '208.80.154.14 208.80.155.119 208.80.153.74'
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
