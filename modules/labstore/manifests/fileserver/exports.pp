class labstore::fileserver::exports {

    # Set to true only for the labstore that is currently
    # actively serving files
    $is_active = (hiera('active_labstore_host') == $::hostname)

    require_package('python3', 'python3-yaml')

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

    file { '/usr/local/sbin/sync-exports':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/sync-exports',
    }

    file { '/etc/nfs-mounts.yaml':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/labstore/nfs-mounts.yaml',
    }

    file { '/usr/local/bin/nfs-exports-daemon':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/nfs-exports-daemon',
    }

    base::service_unit { 'nfs-exports':
        systemd         => true,
        declare_service => false,
    }

    if $is_active {
        nrpe::monitor_systemd_unit_state { 'nfs-exports':
            description => 'Ensure NFS exports are maintained for new instances with NFS',
        }
    }

    file { '/usr/local/sbin/archive-project-volumes':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/archive-project-volumes',
    }
}
