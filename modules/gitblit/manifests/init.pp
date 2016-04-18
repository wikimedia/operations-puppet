# manifest to setup a gitblit instance

# Setup replicated git repos
# Also needs gerrit::replicationdest installed
class gitblit(
    $host           = '',
    $git_repo_owner = 'gerritslave',
) {
    group { 'gitblit':
        ensure => present,
    }

    user { 'gitblit':
        ensure     => present,
        gid        => 'gitblit',
        shell      => '/bin/false',
        home       => '/var/lib/gitblit',
        system     => true,
        managehome => false,
    }

    file { '/var/lib/git':
        ensure => directory,
        mode   => '0644',
        owner  => $git_repo_owner,
        group  => $git_repo_owner,
    }

    file { '/var/lib/gitblit':
        ensure => directory,
        mode   => '0644',
        owner  => 'gitblit',
        group  => 'gitblit',
    }

    file { '/var/lib/gitblit/data/gitblit.properties':
        owner  => 'gitblit',
        group  => 'gitblit',
        mode   => '0444',
        source => 'puppet:///modules/gitblit/gitblit.properties',
    }

    file { '/var/lib/gitblit/data/header.md':
        owner  => 'gitblit',
        group  => 'gitblit',
        mode   => '0444',
        source => 'puppet:///modules/gitblit/header.md',
    }

    file { '/etc/init/gitblit.conf':
        source  => 'puppet:///modules/gitblit/gitblit.conf',
    }

    service { 'gitblit':
        ensure    => running,
        provider  => 'upstart',
        subscribe => File['/var/lib/gitblit/data/gitblit.properties'],
        require   => File['/etc/init/gitblit.conf'],
    }
}
