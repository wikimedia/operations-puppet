class profile::wmcs::nfs::secondary(
    $observer_pass = hiera('profile::openstack::eqiad1::observer_password'),
    $monitor_iface = hiera('profile::wmcs::nfs::secondary::monitor_iface', 'eno0'),
    Stdlib::Host $scratch_active_server = lookup('scratch_active_server'),
    # The following is intentionally using the same value as for scratch.  This may not always
    # be desireable, so a separate parameter is offered.
    Stdlib::Host $maps_active_server = lookup('scratch_active_server'),
    Stdlib::IP::Address $cluster_ip = lookup('profile::wmcs::nfs::secondary::cluster_ip'),
) {
    require ::profile::openstack::eqiad1::clientpackages
    require ::profile::openstack::eqiad1::observerenv

    class {'::labstore':
        nfsd_threads => '192',
    }

    package { [
            'python3-paramiko',
            'python3-pymysql',
        ]:
        ensure => present,
    }

    # class {'labstore::backup_keys': }

    # The following is from the primary cluster and will only be enabled if required
    # sysctl::parameters { 'cloudstore base':
    #     values   => {
    #         # Increase TCP max buffer size
    #         'net.core.rmem_max' => 67108864,
    #         'net.core.wmem_max' => 67108864,

    #         # Increase Linux auto-tuning TCP buffer limits
    #         # Values represent min, default, & max num. of bytes to use.
    #         'net.ipv4.tcp_rmem' => [ 4096, 87380, 33554432 ],
    #         'net.ipv4.tcp_wmem' => [ 4096, 65536, 33554432 ],
    #     },
    #     priority => 70,
    # }

    class {'::labstore::fileserver::exports':
        observer_pass => $observer_pass,
        server_vols   => ['maps-home', 'maps-project'],
    }

    # Enable RPS to balance IRQs over CPUs
    # This breaks the puppet compiler, so re-enable after testing compiles
    # interface::rps { 'monitor':
    #     interface => $monitor_iface,
    # }

    service { 'nfs-server':
        ensure  => 'running',
        require => Package['nfs-kernel-server'],
    }

    # Manage the cluster IP for maps from hiera
    $ipadd_command = "ip addr add ${cluster_ip}/27 dev ${monitor_iface}"
    $ipdel_command = "ip addr del ${cluster_ip}/27 dev ${monitor_iface}"
    if $facts['fqdn'] == $maps_active_server {
        exec { $ipadd_command:
            path    => '/bin:/usr/bin',
            returns => [0, 2],
            unless  => "ip address show ${monitor_iface} | grep -q ${cluster_ip}/27",
        }
    } else {
        exec { $ipdel_command:
            path    => '/bin:/usr/bin',
            returns => [0, 2],
            onlyif  => "ip address show ${monitor_iface} | grep -q ${cluster_ip}/27",
        }
    }


    # TODO: enable monitoring when appropriate
    # class {'labstore::monitoring::exports': }
    # class {'labstore::monitoring::ldap': }
    # class { 'labstore::monitoring::interfaces':
    #     monitor_iface => $monitor_iface,
    # }

    # TODO: replace this
    # class { 'labstore::monitoring::primary':
    #     drbd_role     => $drbd_role,
    #     cluster_iface => $monitor_iface,
    #     cluster_ip    => $cluster_ip,
    # }
}
