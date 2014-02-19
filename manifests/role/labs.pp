
class role::labs::instance {

    include ldap::role::client::labs,
        base::instance-upstarts

    # make common logs readable
    class {'base::syslogs': readable => true }

    # Directory for data mounts
    file { '/data':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # Directory for public (readonly) mounts
    file { '/public':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    if $::site == 'eqiad' {

        $nfs_opts = 'vers=4,bg,hard,intr,sec=sys,proto=tcp,port=0,noatime'
        $nfs_server = 'labstore.svc.eqiad.wmnet'

        mount { '/home':
            ensure => mounted, atboot => true, fstype => 'nfs', options => "rw,${nfs_opts}",
            device => "${nfs_server}:/project/${instanceproject}/home",
        }

        file { '/data/project':
            ensure => directory, owner => 'root', group => 'root', mode => '0755',
            require => File['/data'],
        }
        mount { '/data/project':
            ensure => mounted, atboot => true, fstype => 'nfs', options => "rw,${nfs_opts}",
            device => "${nfs_server}:/project/${instanceproject}/project",
            require => File['/data/project'],
        }

        file { '/data/scratch':
            ensure => directory, owner => 'root', group => 'root', mode => '0755',
            require => File['/data'],
        }
        mount { '/data/scratch':
            ensure => mounted, atboot => true, fstype => 'nfs', options => "rw,${nfs_opts}",
            device => "${nfs_server}:/scratch",
            require => File['/data/scratch'],
        }

        file { '/public/dumps':
            ensure => directory, owner => 'root', group => 'root', mode => '0755',
            require => File['/public'],
        }
        mount { '/public/dumps':
            ensure => mounted, atboot => true, fstype => 'nfs', options => "ro,${nfs_opts}",
            device => "${nfs_server}:/dumps",
            require => File['/public/dumps'],
        }

        file { '/public/backups':
            ensure => directory, owner => 'root', group => 'root', mode => '0755',
            require => File['/public'],
        }
        mount { '/public/backups':
            ensure => mounted, atboot => true, fstype => 'nfs', options => "ro,${nfs_opts}",
            device => "${nfs_server}:/backups",
            require => File['/public/backups'],
        }


        file { '/public/keys':
            ensure => directory, owner => 'root', group => 'root', mode => '0755',
            require => File['/public'],
        }
        mount { '/public/keys':
            ensure => mounted, atboot => true, fstype => 'nfs', options => "ro,${nfs_opts}",
            device => "${nfs_server}:/keys",
            require => File['/public/keys'],
        }

    } else {

        include gluster::client

        # Storage backend to use for /home & /data/project
        # Configured on a per project basis inside puppet since we do not have any
        # other good way to do so yet.
        # FIXME  this is ugly and need to be removed whenever we got rid of
        # the Gluster shared storage.
        if $::instanceproject == 'deployment-prep' {
                include role::labsnfs::client
        }

    }
}

