# == Class puppet::self::gitclone
# Clones the operations/puppet repository
# for use by puppet::self::masters.
#
class puppet::self::gitclone {
    $gitdir = '/var/lib/git'
    $volatiledir = '/var/lib/puppet/volatile'

    include ::puppet::base_repo

    file { "${gitdir}/labs":
        ensure => directory,
        # private repo resides here, so enforce some perms
        owner  => 'root',
        group  => 'puppet',
        mode   => '0640',
    }
    file { $volatiledir:
        ensure => directory,
        owner  => 'root',
        group  => 'puppet',
        mode   => '0750',
    }
    file { "${volatiledir}/misc":
        ensure => directory,
        owner  => 'root',
        group  => 'puppet',
        mode   => '0750',
    }
    git::clone { 'labs/private':
        directory => "${gitdir}/labs/private",
        origin    => 'https://gerrit.wikimedia.org/r/labs/private.git',
        ssh       => "${gitdir}/ssh",
        require   => File["${gitdir}/labs"]
    }

    # Intentionally readable / writeable only by root and puppet
    git::clone { 'labs/puppet-secret':
        ensure    => present,
        directory => "${gitdir}/labs/secret",
        owner     => 'root',
        group     => 'puppet',
        mode      => '0750',
    }

    file { '/etc/puppet/private':
        ensure => link,
        target => "${gitdir}/labs/private",
        force  => true,
    }
    file { '/etc/puppet/secret':
        ensure => link,
        target => "${gitdir}/labs/secret",
        force  => true,
    }
    file { '/etc/puppet/templates':
        ensure => link,
        target => "${gitdir}/operations/puppet/templates",
        force  => true,
    }
    file { '/etc/puppet/files':
        ensure => link,
        target => "${gitdir}/operations/puppet/files",
        force  => true,
    }
    file { '/etc/puppet/manifests':
        ensure => link,
        target => "${gitdir}/operations/puppet/manifests",
        force  => true,
    }
    file { '/etc/puppet/modules':
        ensure => link,
        target => "${gitdir}/operations/puppet/modules",
        force  => true,
    }
}
