class labstore::fileserver::exports(
    $observer_pass,
    ) {
    require_package(['python3-yaml'])

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
        notify  => Service['nfs-exportd'],
    }

    file { '/usr/local/sbin/nfs-manage-binds':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labstore/nfs-manage-binds.py',
        require => File['/etc/nfs-mounts.yaml'],
    }


    file { '/usr/local/bin/nfs-exportd':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labstore/nfs-exportd.py',
        require => File['/usr/local/sbin/nfs-manage-binds'],
        notify  => Service['nfs-exportd'],
    }

    file { '/etc/exports.bak':
        ensure  => directory,
        owner   => 'nfsmanager',
        group   => 'nfsmanager',
        require => File['/usr/local/bin/nfs-exportd'],
    }

    cron { 'archive_export_d':
        command => '/bin/cp -Rp /etc/exports.d /etc/exports.bak',
        user    => 'root',
        weekday => 1,
        hour    => 0,
        minute  => 0,
        require => File['/etc/exports.bak'],
    }

    file { '/usr/local/sbin/archive-project-volumes':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/archive-project-volumes',
    }

    base::service_unit { 'nfs-exportd':
        systemd        => systemd_template('nfs-exportd'),
        service_params => {
            enable => true,
        },
        require        => File['/usr/local/bin/nfs-exportd'],
    }
}
