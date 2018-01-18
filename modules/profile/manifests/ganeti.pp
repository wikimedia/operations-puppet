class profile::ganeti (
    # Interpolate the ganeti_cluster fact to get the list of nodes in a
    # cluster
    $ganeti_nodes = hiera("profile::ganeti::${::ganeti_cluster}::nodes"),
) {

    class { '::ganeti': }

    # Ganeti hosts have KSM enabled. So get stats about it
    diamond::collector { 'KSM':
        ensure => absent,
    }

    # Ganeti needs intracluster SSH root access
    ssh::userkey { 'root-ganeti':
        ensure => present,
        user   => 'root',
        skey   => 'ganeti',
        source => 'puppet:///modules/profile/ganeti/id_dsa.pub',
    }

    # And the private key
    file { '/root/.ssh/id_dsa':
        ensure    => present,
        owner     => 'root',
        group     => 'root',
        mode      => '0400',
        content   => secret('ganeti/id_dsa'),
        show_diff => false,
    }
    # This is here for completeness
    file { '/root/.ssh/id_dsa.pub':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0400',
        source => 'puppet:///modules/profile/ganeti/id_dsa.pub',
    }

    # If ganeti_cluster fact is not defined, the node has not been added to a
    # cluster yet, so don't monitor and don't setup a firewall.
    if $facts['ganeti_cluster'] {

        # Monitoring
        nrpe::monitor_service{ 'ganeti-noded':
            description  => 'ganeti-noded running',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:2 -c 1:2 -u root -C ganeti-noded'
        }

        nrpe::monitor_service{ 'ganeti-confd':
            description  => 'ganeti-confd running',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u gnt-confd -C ganeti-confd'
        }

        nrpe::monitor_service{ 'ganeti-mond':
            description  => 'ganeti-mond running',
            nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u root -C ganeti-mond'
        }

        # Firewalling
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
}
