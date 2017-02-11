class role::pybaltest {
    system::role { 'pybaltest':
        description => 'pybal testing/development'
    }

    include ::base::firewall
    $pybaltest_hosts_ferm = join(hiera('pybaltest::hosts'), ' ')

    ferm::service { 'pybaltest-http':
        proto  => 'tcp',
        port   => '80',
        srange => "@resolve((${pybaltest_hosts_ferm}))",
    }

    ferm::service { 'pybaltest-bgp':
        proto  => 'tcp',
        port   => '581',
        srange => "@resolve((${pybaltest_hosts_ferm}))",
    }
}
