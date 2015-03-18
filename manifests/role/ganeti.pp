# Role classes for ganeti

class role::ganeti {
    include base::firewall
    include ::ganeti

    $ganeti_nodes = hiera('ganeti::%{::ganeti_cluster}::nodes')

    # Ganeti needs intracluster SSH root access
    ssh::userkey { 'root':
        ensure => present,
        source => 'puppet:///files/ganeti/id_rsa.pub',
    }

    file { '/root/.ssh/id_rsa':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
        source => 'puppet:///private/files/ganeti/id_rsa',
    }
    # This is here for completeness
    file { '/root/.ssh/id_rsa.pub':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
        source => 'puppet:///files/ganeti/id_rsa.pub',
    }

    $ganeti_ferm_nodes = join($ganeti_nodes, ' ')

    # Same ganeti actions require SSH
    ferm::service { 'ganeti_ssh_cluster':
        proto  => 'tcp',
        port   => 'ssh',
        srange => "@resolv(($ganeti_ferm_nodes))",
    }
    # RAPI is the API of ganeti
    ferm::service { 'ganeti_rapi_cluster':
        proto  => 'tcp',
        port   => 5080,
        srange => "@resolv($ganeti_ferm_nodes))",
    }
    # Ganeti noded is responsible for all cluster/node actions
    ferm::service { 'ganeti_noded_cluster':
        proto  => 'tcp',
        port   => 1811,
        srange => "@resolv(($ganeti_ferm_nodes))",
    }
    nrpe::monitor_service{ 'ganeti-noded':
        description  => 'ganeti-noded running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u root -C ganeti-noded'
    }

    # Ganeti confd provides a HA and fast way to query cluster configuration
    ferm::service { 'ganeti_noded_cluster':
        proto  => 'udp',
        port   => 1814,
        srange => "@resolv(($ganeti_ferm_nodes))",
    }
    nrpe::monitor_service{ 'ganeti-confd':
        description  => 'ganeti-confd running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u gnt-confd -C ganeti-confd'
    }

    # Ganeti mond is the monitoring daemon. Data is available via port 1815
    ferm::service { 'ganeti_noded_cluster':
        proto  => 'tcp',
        port   => 1815,
        srange => "@resolv(($ganeti_ferm_nodes))",
    }
    nrpe::monitor_service{ 'ganeti-mond':
        description  => 'ganeti-mond running',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u root -C ganeti-mond'
    }
}
