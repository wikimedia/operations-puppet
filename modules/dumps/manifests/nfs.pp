class dumps::nfs(
    $clients = undef,
    $statd_port = undef,
    $statd_out = undef,
    $lockd_udp = undef,
    $lockd_tcp = undef,
    $mountd_port = undef,
    $path = undef,
) {
    file { '/etc/exports':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/generation/nfs_exports.erb'),
        require => Package['nfs-kernel-server'],
    }

    require_package('nfs-kernel-server', 'nfs-common', 'rpcbind')

    service { 'nfs-kernel-server':
        ensure    => 'running',
        require   => [
            Package['nfs-kernel-server'],
            File['/etc/exports'],
        ],
        subscribe => File['/etc/exports'],
    }

    file { '/etc/default/nfs-common':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/generation/default-nfs-common.erb'),
        require => Package['nfs-kernel-server'],
    }

    file { '/etc/default/nfs-kernel-server':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/generation/default-nfs-kernel-server.erb'),
        require => Package['nfs-kernel-server'],
    }

    kmod::options { 'lockd':
        options => "nlm_udpport=${lockd_udp} nlm_tcpport=${lockd_tcp}",
    }

    include ::base::firewall
    include ::network::constants

    ferm::service { 'dumps_nfs':
        proto  => 'tcp',
        port   => '2049',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_rpc_mountd':
        proto  => 'tcp',
        port   => $mountd_port,
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_rpc_statd':
        proto  => 'tcp',
        port   => $statd_port,
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_portmapper_udp':
        proto  => 'udp',
        port   => $portmapper_port,
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_portmapper_tcp':
        proto  => 'tcp',
        port   => $portmapper_port,
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_lockd_udp':
        proto  => 'udp',
        port   => $lockd_udp,
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'nfs_lockd_tcp':
        proto  => 'tcp',
        port   => $lockd_tcp,
        srange => '$PRODUCTION_NETWORKS',
    }

    monitoring::service { 'nfs':
        description   => 'NFS',
        check_command => 'check_tcp!2049',
    }
}
