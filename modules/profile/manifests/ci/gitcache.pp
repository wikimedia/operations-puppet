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
    file { '/srv/git/mediawiki/extensions':
        ensure  => directory,
        require => File['/srv/git/mediawiki'],
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

    git::clone { 'mediawiki/extensions/AbuseFilter':
        directory => '/srv/git/mediawiki/extensions/AbuseFilter.git',
        bare      => true,
        require   => File['/srv/git/mediawiki/extensions'],
    }

    git::clone { 'mediawiki/extensions/MobileFrontend':
        directory => '/srv/git/mediawiki/extensions/MobileFrontend.git',
        bare      => true,
        require   => File['/srv/git/mediawiki/extensions'],
    }

    git::clone { 'mediawiki/extensions/Translate':
        directory => '/srv/git/mediawiki/extensions/Translate.git',
        bare      => true,
        require   => File['/srv/git/mediawiki/extensions'],
    }

    git::clone { 'mediawiki/extensions/VisualEditor':
        directory => '/srv/git/mediawiki/extensions/VisualEditor.git',
        bare      => true,
        require   => File['/srv/git/mediawiki/extensions'],
    }

    git::clone { 'mediawiki/extensions/Wikibase':
        directory => '/srv/git/mediawiki/extensions/Wikibase.git',
        bare      => true,
        require   => File['/srv/git/mediawiki/extensions'],
    }
}
