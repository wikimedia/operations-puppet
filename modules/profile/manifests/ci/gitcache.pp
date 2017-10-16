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

    file { '/srv/git/mediawiki':
        ensure => directory,
    }

    git::clone { 'mediawiki/core':
        directory => '/srv/git/mediawiki/core.git',
        bare      => true,
        require   => File['/srv/git/mediawiki'],
    }

    git::clone { 'mediawiki/vendor':
        directory => '/srv/git/mediawiki/vendor.git',
        bare      => true,
        require   => File['/srv/git/mediawiki'],
    }
}
