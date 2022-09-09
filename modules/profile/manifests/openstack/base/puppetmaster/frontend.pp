class profile::openstack::base::puppetmaster::frontend(
    Array[Stdlib::Fqdn] $openstack_controllers = lookup('profile::openstack::base::openstack_controllers'),
    Array[Stdlib::Fqdn] $designate_hosts = lookup('profile::openstack::base::designate_hosts'),
    $puppetmasters = lookup('profile::openstack::base::puppetmaster::servers'),
    $puppetmaster_ca = lookup('profile::openstack::base::puppetmaster::ca'),
    $puppetmaster_webhostname = lookup('profile::openstack::base::puppetmaster::web_hostname'),
    $cert_secret_path = lookup('profile::openstack::base::puppetmaster::cert_secret_path'),
    ) {

    include ::network::constants

    # validatelabsfqdn will look up an instance certname in nova
    #  and make sure it's for an actual instance before signing
    file { '/usr/local/sbin/validatelabsfqdn.py':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/puppetmaster/validatelabsfqdn.py',
    }

    class { 'profile::openstack::base::puppetmaster::common': }

    $designate_ips = $designate_hosts.map |$host| { ipresolve($host, 4) }
    $designate_ips_v6 = $designate_hosts.map |$host| { ipresolve($host, 6) }
    $openstack_controller_ips = $openstack_controllers.map |$host| { ipresolve($host, 4) }
    $openstack_controller_ips_v6 = $openstack_controllers.map |$host| { ipresolve($host, 6) }

    class { 'puppetmaster::certmanager':
        remote_cert_cleaners => flatten([
            $designate_ips,
            $designate_ips_v6,
            $openstack_controller_ips,
            $openstack_controller_ips_v6,
        ])
    }

    $config = {
        'node_terminus'     => 'exec',
        'external_nodes'    => '/usr/local/bin/puppet-enc',
        'thin_storeconfigs' => false,
        'autosign'          => '/usr/local/sbin/validatelabsfqdn.py',
    }

    class { '::profile::puppetmaster::frontend':
        ca_server      => $puppetmaster_ca,
        web_hostname   => $puppetmaster_webhostname,
        config         => $config,
        secure_private => false,
        servers        => $puppetmasters,
    }

    # The above profile will make a standard vhost for $web_hostname.
    #  We also want to support clients using simple 'puppet'
    #   as the master name.  There's some DNS magic elsewhere
    #   so that VMs can refer to 'puppet' and get a deployment-appropriate
    #   puppetmaster.
    ::puppetmaster::web_frontend { 'puppet':
        master           => $puppetmaster_ca,
        workers          => $puppetmasters[$::fqdn],
        bind_address     => $::puppetmaster::bind_address,
        priority         => 40,
        cert_secret_path => $cert_secret_path,
    }

    $labs_networks = join($network::constants::labs_networks, ' ')
    ferm::rule{'puppetmaster_balancer':
        ensure => 'present',
        rule   => "saddr (${labs_networks})
                          proto tcp dport 8140 ACCEPT;",
    }

    ferm::rule{'puppetcertcleaning':
        ensure => 'present',
        rule   => "saddr (@resolve((${join($designate_hosts,' ')}))
                          @resolve((${join($designate_hosts,' ')}), AAAA))
                        proto tcp dport 22 ACCEPT;",
    }

}
