class role::labs::instance {

    include ::standard
    include ::profile::base::labs
    include sudo
    include ::base::instance_upstarts
    include ::profile::openstack::main::observerenv
    include ::profile::openstack::main::clientpackages
    include ::profile::openstack::eqiad1::cumin::target

    sudo::group { 'ops':
        privileges => ['ALL=(ALL) NOPASSWD: ALL'],
    }

    class { 'profile::ldap::client::labs':
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
    if $mount_nfs {
        require role::labs::nfsclient
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
    if !lookup('diamond::remove', Boolean, 'first' ,false) { # lint:ignore:wmf_styleguide
        diamond::collector::minimalpuppetagent { 'minimal-puppet-agent': }

        diamond::collector { 'SSHSessions':
            source => 'puppet:///modules/diamond/collector/sshsessions.py',
        }
    }

    if os_version('ubuntu >= trusty') {
        package { 'bikeshed':
            ensure => present,
        }
    }

    hiera_include('classes', [])
}
