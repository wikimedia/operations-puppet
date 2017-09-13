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
    $horizon_host_ipv6 = ipresolve(hiera('labs_horizon_host'), 6)
    $designate_host_ip = ipresolve(hiera('labs_designate_hostname'), 4)

    # Only allow puppet access from the instances
    $allow_from = flatten([$labs_instance_range, $labs_metal, '.wikimedia.org'])

    include ::standard
    include ::base::firewall

    include ::profile::puppetmaster::labsenc
    include ::profile::puppetmaster::labsencapi
    include ::profile::openstack::main::cumin::master

    include puppetmaster::labsrootpass

    $config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => true,
    }

    class { '::profile::puppetmaster::backend':
        config           => $config,
        secure_private   => false,
        allow_from       => $allow_from,
        extra_auth_rules => template('role/labs/puppetmaster/extra_auth_rules.conf.erb'),
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
    $all_puppetmasters = inline_template('<%= scope.function_hiera([\'puppetmaster::servers\']).values.flatten(1).map { |p| p[\'worker\'] }.sort.join(\' \')%>')
    $labs_metal_str = inline_template('<%= @labs_metal.join " " %>')

    $fwrules = {
        puppetmaster => {
            rule => "saddr (${labs_vms} ${labs_metal_str} ${monitoring} ${horizon_host_ip} ${horizon_host_ipv6} @resolve((${all_puppetmasters}))) proto tcp dport 8141 ACCEPT;",
        },
        puppetbackend => {
            rule => "saddr (${horizon_host_ip} ${designate_host_ip} ${horizon_host_ipv6}) proto tcp dport 8101 ACCEPT;",
        },
        puppetbackendgetter => {
            rule => "saddr (${labs_vms} ${labs_metal_str} ${monitoring} ${horizon_host_ip} ${horizon_host_ipv6} @resolve((${all_puppetmasters})) @resolve((${all_puppetmasters}), AAAA)) proto tcp dport 8100 ACCEPT;",
        },
    }
    create_resources (ferm::rule, $fwrules)
}
