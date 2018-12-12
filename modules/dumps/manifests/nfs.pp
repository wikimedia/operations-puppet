class dumps::nfs(
    Hash $clients = undef,
    Stdlib::Unixpath $path = undef,
    Stdlib::Port $lockd_udp = undef,
    Stdlib::Port $lockd_tcp = undef,
    Stdlib::Port $mountd_port = undef,
    Stdlib::Port $statd_port = undef,
    Stdlib::Port $statd_out = undef,
) {
    file { '/etc/exports':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/nfs/nfs_exports.erb'),
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
        content => template('dumps/nfs/default-nfs-common.erb'),
        require => Package['nfs-kernel-server'],
    }

    file { '/etc/default/nfs-kernel-server':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumps/nfs/default-nfs-kernel-server.erb'),
        require => Package['nfs-kernel-server'],
    }

    kmod::options { 'lockd':
        options => "nlm_udpport=${lockd_udp} nlm_tcpport=${lockd_tcp}",
    }

    monitoring::service { 'nfs':
        description   => 'NFS',
        check_command => 'check_tcp!2049',
    }
}
