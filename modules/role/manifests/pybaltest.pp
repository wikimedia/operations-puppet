class role::pybaltest {
    system::role { 'pybaltest':
        description => 'pybal testing/development'
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    $pybaltest_hosts_ferm = join(hiera('pybaltest::hosts'), ' ')

    ferm::service { 'pybaltest-http':
        proto  => 'tcp',
        port   => '80',
        srange => "(@resolve((${pybaltest_hosts_ferm})) @resolve((${pybaltest_hosts_ferm}), AAAA))",
    }

    ferm::service { 'pybaltest-bgp':
        proto  => 'tcp',
        port   => '179',
        srange => "(@resolve((${pybaltest_hosts_ferm})) @resolve((${pybaltest_hosts_ferm}), AAAA))",
    }

    # If the host considers itself as a router (IP forwarding enabled), it will
    # ignore all router advertisements, breaking IPv6 SLAAC. Accept Router
    # Advertisements even if forwarding is enabled.
    sysctl::parameters { 'accept-ra':
        values => {
            "net.ipv6.conf.${facts['interface_primary']}.accept_ra" => 2,
        },
    }

    # Install conftool-master for conftool testing
    class  { '::puppetmaster::base_repo':
        gitdir   => '/var/lib/git',
        gitowner => 'root',
    }


    include ::profile::conftool::master
}
