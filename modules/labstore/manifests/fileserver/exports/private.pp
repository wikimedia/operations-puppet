# = Class labstore::fileserver::exports::private
#
# Sets up per-project private NFS exports so that
# instances in a project have access to NFS mounts
# specifically set aside for them
class labstore::fileserver::exports::private {
    require_package('python3', 'python3-yaml')

    require ::labstore::fileserver::exports

    sudo::user { 'nfsmanager':
        privileges => [
            'ALL = NOPASSWD: /bin/mkdir -p /srv/*',
            'ALL = NOPASSWD: /bin/rmdir /srv/*',
            'ALL = NOPASSWD: /usr/local/sbin/sync-exports',
            'ALL = NOPASSWD: /usr/sbin/exportfs',
        ],
        require => User['nfsmanager'],
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
        notify => Service['nfs-exports'],
    }

    base::service_unit { 'nfs-exports':
        ensure  => present,
        systemd => true,
    }

    file { '/usr/local/sbin/archive-project-volumes':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/archive-project-volumes',
    }
}
