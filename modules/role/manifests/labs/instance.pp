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

    # Allows per-host overriding of NFS mounts
    $mount_nfs = hiera('mount_nfs', true)
    # No NFS on labs metal for now.
    if $::virtual == 'kvm' and $mount_nfs{
        require role::labs::nfsclient
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

    # For historical reasons, LDAP users start at uid/gid 500, so we
    # need to guard against system users being created in that range.
    file_line { 'login.defs-SYS_UID_MAX':
        path     => '/etc/login.defs',
        match    => '#?SYS_UID_MAX\b',
        line     => 'SYS_UID_MAX               499',
    }
    file_line { 'login.defs-SYS_GID_MAX':
        path     => '/etc/login.defs',
        match    => '#?SYS_GID_MAX\b',
        line     => 'SYS_GID_MAX               499',
    }

    hiera_include('classes', [])
}
