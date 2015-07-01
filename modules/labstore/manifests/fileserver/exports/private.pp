# = Class labstore::fileserver::exports::private
#
# Sets up per-project private NFS exports so that
# instances in a project have access to NFS mounts
# specifically set aside for them
class labstore::fileserver::exports::private {
    require_package('python3', 'python3-yaml')

    require ::labstore::fileserver::exports

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

    sudo::user { 'nfsmanager':
        privileges => [
            'ALL = NOPASSWD: /bin/mkdir -p /srv/*',
            'ALL = NOPASSWD: /bin/rmdir /srv/*',
            'ALL = NOPASSWD: /usr/local/sbin/sync-exports'
        ],
        require => User['nfsmanager'],
    }

    file { '/usr/local/sbin/sync-exports':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/sync-exports',
    }

    file { '/etc/projects-nfs-config.yaml':
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/labstore/projects-nfs-config.yaml',
    }

    file { '/usr/local/bin/nfs-project-exports-daemon':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/labstore/nfs-project-exports-daemon',
    }

    base::service_unit { 'nfs-project-exports':
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
