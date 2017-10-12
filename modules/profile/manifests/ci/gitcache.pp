class profile::ci::gitcache {
    file { '/srv/git':
        ensure => directory,
    }
    file { '/srv/git/operations':
        ensure => directory,
    }
    git::clone { 'operations/puppet':
        directory => '/srv/git/operations/puppet.git',
        bare      => true,
        require   => File['/srv/git/operations'],
    }
}
