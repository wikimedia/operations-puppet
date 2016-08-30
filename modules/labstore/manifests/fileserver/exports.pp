class labstore::fileserver::exports {

    package { [
        'python3',
        'python3-yaml',
        ]: }

    group { 'nfsmanager':
        ensure => present,
        name   => 'nfsmanager',
        system => true,
    }

    user { 'nfsmanager':
        home       => '/var/lib/nfsmanager',
        shell      => '/bin/bash',
        managehome => true,
        system     => true,
    }

    file { '/etc/exports.d':
        ensure => directory,
        owner  => 'root',
        group  => 'nfsmanager',
        mode   => '2775',
    }

    sudo::user { 'nfsmanager':
        privileges => [
            'ALL = NOPASSWD: /bin/mkdir -p /srv/*',
            'ALL = NOPASSWD: /bin/rmdir /srv/*',
            'ALL = NOPASSWD: /usr/local/sbin/sync-exports',
            'ALL = NOPASSWD: /usr/sbin/exportfs',
        ],
        require    => User['nfsmanager'],
    }

    file { '/etc/nfs-mounts.yaml':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/labstore/nfs-mounts.yaml',
        require => [Package['python3'], Package['python3-yaml']],
    }

    file { '/usr/local/sbin/sync-exports':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labstore/sync-exports',
        require => File['/etc/nfs-mounts.yaml'],
    }

    file { '/usr/local/bin/nfs-exports-daemon':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labstore/nfs-exports-daemon',
        require => File['/usr/local/sbin/sync-exports'],
    }

    file { '/usr/local/sbin/archive-project-volumes':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/archive-project-volumes',
    }

    base::service_unit { 'nfs-exports':
        systemd         => true,
        declare_service => false,
        require         => File['/usr/local/bin/nfs-exports-daemon'],
    }
}
