
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

    $nfs_opts = 'vers=4,bg,hard,intr,sec=sys,proto=tcp,port=0,noatime,nofsc'
    $nfs_server = 'labstore.svc.eqiad.wmnet'

    mount { '/home':
        ensure => mounted, atboot => true, fstype => 'nfs', options => "rw,${nfs_opts}",
        device => "${nfs_server}:/project/${instanceproject}/home",
    }

    file { '/data/project':
        ensure => directory,
        require => File['/data', '/etc/idmapd.conf'],
    }
    mount { '/data/project':
        ensure => mounted, atboot => true, fstype => 'nfs', options => "rw,${nfs_opts}",
        device => "${nfs_server}:/project/${instanceproject}/project",
        require => File['/data/project'],
    }

    file { '/data/scratch':
        ensure => directory,
        require => File['/data', '/etc/idmapd.conf'],
    }
    mount { '/data/scratch':
        ensure => mounted, atboot => true, fstype => 'nfs', options => "rw,${nfs_opts}",
        device => "${nfs_server}:/scratch",
        require => File['/data/scratch'],
    }

    file { '/public/dumps':
        ensure => directory,
        require => File['/public'],
    }
    mount { '/public/dumps':
        ensure => mounted, atboot => true, fstype => 'nfs', options => "ro,${nfs_opts}",
        device => "${nfs_server}:/dumps",
        require => File['/public/dumps'],
    }

    file { '/public/backups':
        ensure => directory,
        require => File['/public'],
    }
    mount { '/public/backups':
        ensure => mounted, atboot => true, fstype => 'nfs', options => "ro,${nfs_opts}",
        device => "${nfs_server}:/backups",
        require => File['/public/backups'],
    }


    file { '/public/keys':
        ensure => directory,
        require => File['/public'],
    }
    mount { '/public/keys':
        ensure => mounted, atboot => true, fstype => 'nfs', options => "ro,${nfs_opts}",
        device => "${nfs_server}:/keys",
        require => File['/public/keys'],
        notify => Service['ssh'],
    }

    service { 'idmapd':
        ensure => running,
        subscribe => File['/etc/idmapd.conf'],
    }

    file { '/etc/idmapd.conf':
        ensure => present,
        owner => root,
        group => root,
        mode => 0444,
        source => 'puppet:///files/nfs/idmapd.conf',
    }

}

