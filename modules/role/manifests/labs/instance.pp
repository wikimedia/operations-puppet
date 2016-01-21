class role::labs::instance {

    include standard
    include base::labs
    include sudo
    include base::instance_upstarts

    sudo::group { 'ops':
        privileges => ['ALL=(ALL) NOPASSWD: ALL'],
    }

    class { 'ldap::role::client::labs':
        # Puppet requires ldap, so we need to update ldap before anything
        #  happens to puppet.
        before => File['/etc/puppet/puppet.conf'],
    }

    # make common logs readable
    class { 'base::syslogs':
        readable => true,
    }

    file { '/etc/mailname':
        ensure  => present,
        content => "${::fqdn}\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    package { 'puppet-lint':
        ensure => present,
    }

    # No NFS on labs metal for now.
    if $::virtual == 'kvm' {
        # This script will block until the NFS volume is available
        file { '/usr/local/sbin/block-for-export':
            ensure => present,
            owner  => root,
            mode   => '0555',
            source => 'puppet:///files/nfs/block-for-export',
        }

        $nfs_opts = 'vers=4,bg,hard,intr,sec=sys,proto=tcp,port=0,noatime,lookupcache=none,nofsc'
        $nfs_server = 'labstore.svc.eqiad.wmnet'
        $dumps_server = 'labstore1003.eqiad.wmnet'

        # Allows per-host overriding of NFS mounts
        $mount_nfs = hiera('mount_nfs', true)

        if mount_nfs_volume($::labsproject, 'home') and $mount_nfs {
            # Note that this is the same export as for /data/project
            exec { 'block-for-home-export':
                command => "/usr/local/sbin/block-for-export ${nfs_server} project/${::labsproject} 180",
                require => [File['/etc/modprobe.d/nfs-no-idmap'], File['/usr/local/sbin/block-for-export']],
                unless  => '/bin/mountpoint -q /home',
            }

            mount { '/home':
                ensure  => mounted,
                atboot  => true,
                fstype  => 'nfs',
                options => "rw,${nfs_opts}",
                device  => "${nfs_server}:/project/${labsproject}/home",
                require => [File['/etc/modprobe.d/nfs-no-idmap'], Exec['block-for-home-export']],
            }
        }

        if mount_nfs_volume($::labsproject, 'project') or mount_nfs_volume($::labsproject, 'scratch') {
            # Directory for data mounts
            file { '/data':
                ensure => directory,
                owner  => 'root',
                group  => 'root',
                mode   => '0755',
            }
        }

        if mount_nfs_volume($::labsproject, 'project') and $mount_nfs {
            exec { 'block-for-project-export':
                command => "/usr/local/sbin/block-for-export ${nfs_server} project/${::labsproject} 180",
                require => [File['/etc/modprobe.d/nfs-no-idmap'], File['/usr/local/sbin/block-for-export']],
                unless  => '/bin/mountpoint -q /data/project',
            }

            file { '/data/project':
                ensure  => directory,
                require => File['/data'],
            }

            mount { '/data/project':
                ensure  => mounted,
                atboot  => true,
                fstype  => 'nfs',
                options => "rw,${nfs_opts}",
                device  => "${nfs_server}:/project/${labsproject}/project",
                require => [File['/data/project', '/etc/modprobe.d/nfs-no-idmap'], Exec['block-for-project-export']],
            }
        }

        if mount_nfs_volume($::labsproject, 'scratch') and $mount_nfs {
            # We don't need to block for this one because it's always exported for everyone.
            file { '/data/scratch':
                ensure  => directory,
                require => File['/data'],
            }

            mount { '/data/scratch':
                ensure  => mounted,
                atboot  => true,
                fstype  => 'nfs',
                options => "rw,${nfs_opts}",
                device  => "${nfs_server}:/scratch",
                require => File['/data/scratch', '/etc/modprobe.d/nfs-no-idmap'],
            }
        }

        if mount_nfs_volume($::labsproject, 'dumps') or mount_nfs_volume($::labsproject, 'statistics') {
            # Directory for public (readonly) mounts
            file { '/public':
                ensure => directory,
                owner  => 'root',
                group  => 'root',
                mode   => '0755',
            }
        }

        if mount_nfs_volume($::labsproject, 'statistics') and $mount_nfs {
            file { '/public/statistics':
                ensure  => directory,
                require => File['/public'],
            }

            mount { '/public/statistics':
                ensure  => mounted,
                atboot  => true,
                fstype  => 'nfs',
                options => "ro,${nfs_opts}",
                device  => "${dumps_server}:/statistics",
                require => File['/public/statistics', '/etc/modprobe.d/nfs-no-idmap'],
            }
        }

        if mount_nfs_volume($::labsproject, 'dumps') and $mount_nfs {
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
                require => File['/public/dumps', '/etc/modprobe.d/nfs-no-idmap'],
            }
        }
    }

    if os_version('ubuntu <= precise') {
        # Was used by ssh earlier, not any more
        # Remove in a few weeks?
        file { '/public/keys':
            ensure  => absent,
            force   => true,
            require => Mount['/public/keys'],
        }

        mount { '/public/keys':
            ensure  => absent,
        }
    }

    # While the default on kernels >= 3.3 is to have idmap disabled,
    # doing so explicitly does no harm and ensures it is everywhere.

    file { '/etc/modprobe.d/nfs-no-idmap':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "options nfs nfs4_disable_idmapping=1\n",
    }

    file { '/etc/idmapd.conf':
        ensure => absent,
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

    diamond::collector { 'SSHSessions':
        source => 'puppet:///modules/diamond/collector/sshsessions.py',
    }

    diamond::collector { 'NscdCollector':
        source => 'puppet:///modules/ldap/monitor/nscd.py',
    }

    hiera_include('classes', [])
}
