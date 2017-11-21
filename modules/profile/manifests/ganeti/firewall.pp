class profile::ganeti::firewall {

    # Interpolate the ganeti_cluster fact to get the list of nodes in a
    # cluster
    $ganeti_nodes = hiera("ganeti::${::ganeti_cluster}::nodes")
    $ganeti_ferm_nodes = join($ganeti_nodes, ' ')

    # Same ganeti actions require SSH
    ferm::service { 'ganeti_ssh_cluster':
        proto  => 'tcp',
        port   => 'ssh',
        srange => "@resolve((${ganeti_ferm_nodes}))",
    }

    # RAPI is the API of ganeti
    ferm::service { 'ganeti_rapi_cluster':
        proto  => 'tcp',
        port   => 5080,
        srange => "@resolve((${ganeti_ferm_nodes}))",
    }

    # Ganeti noded is responsible for all cluster/node actions
    ferm::service { 'ganeti_noded_cluster':
        proto  => 'tcp',
        port   => 1811,
        srange => "@resolve((${ganeti_ferm_nodes}))",
    }

    # Ganeti confd provides a HA and fast way to query cluster configuration
    ferm::service { 'ganeti_confd_cluster':
        proto  => 'udp',
        port   => 1814,
        srange => "@resolve((${ganeti_ferm_nodes}))",
    }

    # Ganeti mond is the monitoring daemon. Data is available via port 1815
    ferm::service { 'ganeti_mond_cluster':
        proto  => 'tcp',
        port   => 1815,
        srange => "@resolve((${ganeti_ferm_nodes}))",
    }

    # DRBD is used for HA of disk images. Port range for ganeti is
    # 11000-14999
    ferm::service { 'ganeti_drbd':
        proto  => 'tcp',
        port   => '11000:14999',
        srange => "@resolve((${ganeti_ferm_nodes}))",
    }

    # Migration is done over TCP port
    ferm::service { 'ganeti_migration':
        proto  => 'tcp',
        port   => 8102,
        srange => "@resolve((${ganeti_ferm_nodes}))",
    }
}
