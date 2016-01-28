class dataset::nfs($enable=true) {

    if ($enable) {
        $service_ensure = 'running'
        $role_ensure = 'present'
    }
    else {
        $service_ensure = 'stopped'
        $role_ensure = 'absent'
    }

    file { '/etc/exports':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dataset/exports',
        require => Package['nfs-kernel-server'],
    }

    package { 'nfs-kernel-server':
        ensure => present,
    }

    service { 'nfs-kernel-server':
        ensure  => $::nfs_ensure,
        require => [
            Package['nfs-kernel-server'],
            File['/etc/exports'],
        ],
    }

    file { '/etc/default/nfs-common':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dataset/default-nfs-common',
        require => Package['nfs-kernel-server'],
    }

    file { '/etc/default/nfs-kernel-server':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        source  => 'puppet:///modules/dataset/default-nfs-kernel-server',
        require => Package['nfs-kernel-server'],
    }

    monitoring::service { 'nfs':
        description   => 'NFS',
        check_command => 'check_tcp!2049',
    }

    ferm::service { 'nfs_rpc_mountd':
        proto  => 'tcp',
        port   => '32767',
        srange => '$INTERNAL',
    }

    ferm::service { 'nfs_rpc_statd':
        proto  => 'tcp',
        port   => '32765',
        srange => '$INTERNAL',
    }

    ferm::service { 'nfs_portmapper_udp':
        proto  => 'udp',
        port   => '111',
        srange => '$INTERNAL',
    }

    ferm::service { 'nfs_portmapper_tcp':
        proto  => 'tcp',
        port   => '111',
        srange => '$INTERNAL',
    }
}
