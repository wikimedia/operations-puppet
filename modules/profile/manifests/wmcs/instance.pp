# basic profile for every CloudVPS instance
class profile::wmcs::instance(
    Boolean $mount_nfs      = lookup('mount_nfs', {default_value => true}),
    Boolean $diamond_remove = lookup('diamond::remove', {default_value => false}),
    String  $sudo_flavor    = lookup('sudo_flavor', {default_value => 'sudoldap'}),
) {
    if $sudo_flavor == 'sudo' {
        if ! defined(Class['Sudo']) {
            class { '::sudo': }
        }
    } else {
        if ! defined(Class['Sudo::Sudoldap']) {
            class { '::sudo::sudoldap': }
        }
    }

    sudo::group { 'ops':
        privileges  => ['ALL=(ALL) NOPASSWD: ALL'],
        sudo_flavor => $sudo_flavor,
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
    if $mount_nfs {
        require profile::wmcs::nfsclient
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
    if ! $diamond_remove {
        diamond::collector::minimalpuppetagent { 'minimal-puppet-agent':
            sudo_flavor => $sudo_flavor,
        }

        diamond::collector { 'SSHSessions':
            source => 'puppet:///modules/diamond/collector/sshsessions.py',
        }
    }

    hiera_include('classes', [])
}
