class role::labs::instance {

    include standard
    include sudo

    if os_version('ubuntu > lucid') {
        include base::instance-upstarts
    }

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

    $nfs_mounts = hiera('nfs_mounts')

    $nfs_opts = 'vers=4,bg,hard,intr,sec=sys,proto=tcp,port=0,noatime,nofsc'
    $nfs_server = 'labstore.svc.eqiad.wmnet'
    $dumps_server = 'labstore1003.eqiad.wmnet'

    if $nfs_mounts['home'] {
        mount { '/home':
            ensure  => mounted,
            atboot  => true,
            fstype  => 'nfs',
            options => "rw,${nfs_opts}",
            device  => "${nfs_server}:/project/${instanceproject}/home",
            require => File['/etc/modprobe.d/nfs-no-idmap'],
        }
    }

    if $nfs_mounts['project'] or $nfs_mounts['scratch'] {
        # Directory for data mounts
        file { '/data':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    if $nfs_mounts['project'] {
        file { '/data/project':
            ensure  => directory,
            require => File['/data'],
        }

        mount { '/data/project':
            ensure  => mounted,
            atboot  => true,
            fstype  => 'nfs',
            options => "rw,${nfs_opts}",
            device  => "${nfs_server}:/project/${instanceproject}/project",
            require => File['/data/project', '/etc/modprobe.d/nfs-no-idmap'],
        }
    }

    if $nfs_mounts['scratch'] {
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

    # Only create if we need /public/dumps or /public/keys
    if $nfs_mounts['dumps'] or os_version('ubuntu <= precise') {
        # Directory for public (readonly) mounts
        file { '/public':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    if $nfs_mounts['dumps'] {
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

    # Used by ssh for logging in, only on precise and lower
    if os_version('ubuntu <= precise') {
        file { '/public/keys':
            ensure  => directory,
            require => File['/public'],
        }

        mount { '/public/keys':
            ensure  => absent,
        }


        exec { '/usr/local/sbin/manage-keys-nfs':
            require => [File['/public/keys'], File['/usr/local/sbin/manage-keys-nfs']],
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

    # This short script allows verifying whether an instance uses
    # idmap and will reboot it if it does.  It's meant to be invoked
    # by salt, not automatically.

    file { '/usr/local/sbin/reboot-if-idmap':
        ensure => present,
        owner  => root,
        mode   => '0555',
        source => 'puppet:///files/nfs/reboot-if-idmap',
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

    hiera_include('classes', [])

    # These notifications are processed by the labsstatus.rb Puppet
    # report handler.  It needs to know project/hostname to update the
    # instance's Puppet status on wikitech.
    notice("instanceproject: ${::instanceproject}")
    notice("hostname: ${::instancename}")
}
