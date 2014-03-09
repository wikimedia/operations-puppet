class dataset::nfs($enable=true) {

    if ($enable) {
        $service_ensure = 'running'
        $role_ensure = 'present'
    }
    else {
        $service_ensure = 'stopped'
        $role_ensure = 'absent'
    }

    system::role { 'dataset::nfs':
        ensure      => $role_ensure,
        description => 'nfs server of dumps and other datasets'
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
        ensure  => $nfs_ensure,
        require => [ Package['nfs-kernel-server'], File['/etc/exports'] ],
    }

    monitor_service { 'nfs':
        description   => 'NFS',
        check_command => 'check_tcp!2049',
    }

}
