class role::labs::instance {

    include standard
    include ldap::role::client::labs
    include base::instance-upstarts
    include role::mail::sender

    # make common logs readable
    class { 'base::syslogs':
        readable => true,
    }

    # Directory for data mounts
    file { '/data':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    file { '/etc/mailname':
        ensure  => present,
        content => "${::fqdn}\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    # Directory for public (readonly) mounts
    file { '/public':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    package { 'puppet-lint':
        ensure => present,
    }

    $nfs_opts = 'vers=4,bg,hard,intr,sec=sys,proto=tcp,port=0,noatime,nofsc'
    $nfs_server = 'labstore.svc.eqiad.wmnet'
    $dumps_server = 'labstore1003.eqiad.wmnet'

    mount { '/home':
        ensure  => mounted,
        atboot  => true,
        fstype  => 'nfs',
        options => "rw,${nfs_opts}",
        device  => "${nfs_server}:/project/${instanceproject}/home",
    }

    file { '/data/project':
        ensure  => directory,
        require => File['/data',
                        '/etc/idmapd.conf'
                    ],
    }

    mount { '/data/project':
        ensure  => mounted,
        atboot  => true,
        fstype  => 'nfs',
        options => "rw,${nfs_opts}",
        device  => "${nfs_server}:/project/${instanceproject}/project",
        require => File['/data/project'],
    }

    file { '/data/scratch':
        ensure  => directory,
        require => File['/data',
                        '/etc/idmapd.conf'
                    ],
    }
    mount { '/data/scratch':
        ensure  => mounted,
        atboot  => true,
        fstype  => 'nfs',
        options => "rw,${nfs_opts}",
        device  => "${nfs_server}:/scratch",
        require => File['/data/scratch'],
    }

    file { '/public/dumps':
        ensure  => directory,
        require => File['/public'],
    }
    mount { '/public/dumps':
        ensure  => mounted,
        atboot  => true,
        fstype  => 'nfs',
        options => "ro,${nfs_opts}",
        device  => "${dumps_server}:/dumps",
        require => File['/public/dumps'],
    }

    file { '/public/backups':
        ensure  => directory,
        require => File['/public'],
    }
    mount { '/public/backups':
        ensure  => mounted,
        atboot  => true,
        fstype  => 'nfs',
        options => "ro,${nfs_opts}",
        device  => "${nfs_server}:/backups",
        require => File['/public/backups'],
    }


    file { '/public/keys':
        ensure  => directory,
        require => File['/public'],
    }
    mount { '/public/keys':
        ensure  => mounted,
        atboot  => true,
        fstype  => 'nfs',
        options => "ro,${nfs_opts}",
        device  => "${nfs_server}:/keys",
        require => File['/public/keys'],
        notify  => Service['ssh'],
    }

    service { 'idmapd':
        ensure    => running,
        subscribe => File['/etc/idmapd.conf'],
        provider  => upstart,
    }

    file { '/etc/idmapd.conf':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///files/nfs/idmapd.conf',
    }

    # In production, we try to be punctilious about having Puppet manage
    # system state, and thus it's reasonable to purge Apache site configs
    # that have not been declared via Puppet. But on Labs we want to allow
    # users to manage configuration files locally if they so choose,
    # without having Puppet clobber them. So provision a
    # /etc/apache2/sites-local directory for Apache to recurse into during
    # initialization, but do not manage its contents.
    exec { 'enable_sites_local':
        command => '/bin/mkdir -m0755 /etc/apache2/sites-local && \
                    /usr/bin/touch /etc/apache2/sites-local/dummy.conf && \
                    /bin/echo "Include sites-local/*" >> /etc/apache2/apache2.conf',
        onlyif  => '/usr/bin/test -d /etc/apache2 -a ! -d /etc/apache2/sites-local',
    }

    # In production, puppet freshness checks are done by icinga. Labs has no
    # icinga, so collect puppet freshness metrics via diamond/graphite
    diamond::collector::minimalpuppetagent { 'minimal-puppet-agent': }
}
