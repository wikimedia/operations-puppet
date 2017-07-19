class dumpsdata::nfs() {

    $clients = hiera('dumpsdata_clients_snapshots')

    file { '/etc/exports':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dumpsdata/nfs_exports.erb'),
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
        source  => 'puppet:///modules/dumpsdata/default-nfs-common',
        require => Package['nfs-kernel-server'],
    }

    file { '/etc/default/nfs-kernel-server':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dumpsdata/default-nfs-kernel-server',
        require => Package['nfs-kernel-server'],
    }

    monitoring::service { 'nfs':
        description   => 'NFS',
        check_command => 'check_tcp!2049',
    }

    file { '/etc/modprobe.d/nfs-lockd.conf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => 'options lockd nlm_udpport=32768 nlm_tcpport=32769',
    }
}
