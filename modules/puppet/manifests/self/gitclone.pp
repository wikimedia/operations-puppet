# == Class puppet::self::gitclone
# Clones the operations/puppet repository
# for use by puppet::self::masters.
#
class puppet::self::gitclone {
    $gitdir = '/var/lib/git'
    $volatiledir = '/var/lib/puppet/volatile'

    file { $gitdir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }
    file { "${gitdir}/operations":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
    }
    file { "${gitdir}/labs":
        ensure => directory,
        # private repo resides here, so enforce some perms
        owner  => 'root',
        group  => 'puppet',
        mode   => '0640',
    }
    file { "${gitdir}/ssh":
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        # FIXME: ok, this sucks. ew. ewww.
        content => "#!/bin/sh\nexec ssh -o StrictHostKeyChecking=no -i ${gitdir}/labs-puppet-key \$*\n",
        require => File["${gitdir}/labs-puppet-key"],
    }
    file { "${gitdir}/labs-puppet-key":
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0600',
        source => 'puppet:///private/ssh/labs-puppet-key',
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
    git::clone { 'operations/puppet':
        directory          => "${gitdir}/operations/puppet",
        branch             => 'production',
        origin             => 'https://gerrit.wikimedia.org/r/operations/puppet.git',
        recurse_submodules => true,
        require            => File["${gitdir}/operations"],
    }
    git::clone { 'labs/private':
        directory => "${gitdir}/labs/private",
        origin    => 'ssh://labs-puppet@gerrit.wikimedia.org:29418/labs/private.git',
        ssh       => "${gitdir}/ssh",
        require   => [ File["${gitdir}/labs"], File["${gitdir}/ssh"] ],
    }
    file { '/etc/puppet/private':
        ensure => link,
        target => "${gitdir}/labs/private",
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
