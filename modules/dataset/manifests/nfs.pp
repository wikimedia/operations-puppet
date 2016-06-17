class dataset::nfs($enable=true) {

    if ($enable) {
        $service_ensure = 'running'
        $role_ensure = 'present'
    }
    else {
        $service_ensure = 'stopped'
        $role_ensure = 'absent'
    }

    $dataset_clients_snapshots = hiera('dataset_clients_snapshots')
    $dataset_clients_other = hiera('dataset_clients_other')

    file { '/etc/exports':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('dataset/nfs_exports.erb'),
        require => Package['nfs-kernel-server'],
    }

    package { 'nfs-kernel-server':
        ensure => present,
    }

    service { 'nfs-kernel-server':
        ensure    => $service_ensure,
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
}
