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

    # Effectively replaces /usr/local/sbin/sync-exports but
    # makes assumptions only true on newer systems at the moment
    file { '/usr/local/sbin/nfs-manage-binds':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labstore/nfs-manage-binds',
        require => File['/etc/nfs-mounts.yaml'],
    }

    file { '/usr/local/sbin/sync-exports':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labstore/sync-exports',
        require => File['/etc/nfs-mounts.yaml'],
    }

    include ::openstack::clientlib
    file { '/usr/local/bin/nfs-exportd':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/labstore/nfs-exportd',
        require => File['/usr/local/sbin/sync-exports'],
    }

    file { '/usr/local/sbin/archive-project-volumes':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/archive-project-volumes',
    }

    $novaconfig = hiera_hash('novaconfig', {})
    $observer_pass = $novaconfig['observer_password']
    base::service_unit { 'nfs-exportd':
        systemd        => true,
        service_params => {
            enable => true,
        },
        require        => File['/usr/local/bin/nfs-exportd'],
    }
}
