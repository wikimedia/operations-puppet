class profile::wmcs::nfs::secondary(
    String $observer_pass = lookup('profile::openstack::eqiad1::observer_password'),
    String $monitor_iface = lookup('profile::wmcs::nfs::secondary::monitor_iface', {'default_value' => 'eno0'}),
    Stdlib::Host $scratch_active_server = lookup('scratch_active_server'),
    # The following is intentionally using the same value as for scratch.  This may not always
    # be desireable, so a separate parameter is offered.
    Stdlib::Host $maps_active_server = lookup('scratch_active_server'),
    Stdlib::IP::Address $cluster_ip = lookup('profile::wmcs::nfs::secondary::cluster_ip'),
    Array[Stdlib::Host] $secondary_servers = lookup('secondary_nfs_servers'),
) {
    require ::profile::openstack::eqiad1::clientpackages
    require ::profile::openstack::eqiad1::observerenv

    class {'::labstore':
        nfsd_threads => 192,
    }

    ensure_packages([
        'python3-paramiko',
        'python3-pymysql',
        'python3-dateutil',
    ])

    class {'::labstore::fileserver::exports':
        server_vols   => ['maps'],
    }

    # Enable RPS to balance IRQs over CPUs
    # This breaks the puppet compiler, so re-enable after testing compiles
    # interface::rps { 'monitor':
    #     interface => $monitor_iface,
    # }

    # The service should remain running always on this because there's no DRBD
    service { 'nfs-server':
        ensure  => 'running',
        require => Package['nfs-kernel-server'],
    }

    # Manage the cluster IP for maps from hiera
    $ipadd_command = "ip addr add ${cluster_ip}/27 dev ${monitor_iface}"
    $ipdel_command = "ip addr del ${cluster_ip}/27 dev ${monitor_iface}"

    # Because in this simple failover, we don't have STONITH, don't claim
    # the IP unless is doesn't work
    if $facts['fqdn'] == $maps_active_server {
        exec { $ipadd_command:
            path    => '/bin:/usr/bin',
            returns => [0, 2],
            unless  => "ping -n -c1 ${cluster_ip} > /dev/null",
        }

    } else {
        exec { $ipdel_command:
            path    => '/bin:/usr/bin',
            returns => [0, 2],
            onlyif  => "ip address show ${monitor_iface} | grep -q ${cluster_ip}/27",
        }
    }

    class {'labstore::monitoring::exports': }
    class {'labstore::monitoring::ldap': }
    class {'labstore::monitoring::volumes':
        server_vols => [
            '/srv/scratch',
            '/srv/maps'
        ],
    }
    class { 'labstore::monitoring::interfaces':
        monitor_iface       => 'eno1',
        int_throughput_warn => 937500000,  # 7500Mbps
        int_throughput_crit => 1062500000, # 8500Mbps
    }

    $secondary_servers_ferm = join($secondary_servers, ' ')
    ferm::service { 'labstore_nfs_portmapper_udp_monitor':
        proto  => 'udp',
        port   => '111',
        srange => "(@resolve((${secondary_servers_ferm})) @resolve((${secondary_servers_ferm}), AAAA))",
    }
    ferm::service { 'labstore_nfs_monitor':
        proto  => 'tcp',
        port   => '2049',
        srange => "(@resolve((${secondary_servers_ferm})) @resolve((${secondary_servers_ferm}), AAAA))",
    }
    ferm::service { 'labstore_nfs_cluster_rpc_mountd':
        proto  => 'tcp',
        port   => '38466',
        srange => "(@resolve((${secondary_servers_ferm})) @resolve((${secondary_servers_ferm}), AAAA))",
    }

    nrpe::monitor_service { 'check_nfs_status':
        description   => 'NFS port is open on cluster IP',
        nrpe_command  => "/usr/lib/nagios/plugins/check_tcp -H ${cluster_ip} -p 2049 --timeout=2",
        contact_group => 'wmcs-team',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Portal:Data_Services/Admin/Labstore',
    }
}
