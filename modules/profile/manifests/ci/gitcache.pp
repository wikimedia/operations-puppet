# SPDX-License-Identifier: Apache-2.0
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

    systemd::timer::job { 'operations-puppet':
        ensure      => absent,
        description => 'Regular jobs to update gitcache for operations/puppet',
        user        => 'root',
        command     => '/usr/bin/git -C /srv/git/operations/puppet.git fetch origin --prune +refs/heads/*:refs/heads/*',
        require     => Git::Clone['operations/puppet'],
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 3:00:00'},
    }

    $minute = fqdn_rand(60)

    systemd::timer::job { 'ci-gitcache-refresh':
        ensure      => present,
        description => 'Regular job to update the CI git cache',
        user        => 'root',
        command     => '/usr/bin/find /srv/git -type d -name \'*.git\' -exec git -C {} fetch origin --prune \'+refs/heads/*:refs/heads/*\' \;',
        interval    => {'start' => 'OnCalendar', 'interval' => "*-*-* 3:${minute}:00"},
    }

    file { '/srv/git/mediawiki':
        ensure => directory,
    }
    file { '/srv/git/mediawiki/extensions':
        ensure  => directory,
        require => File['/srv/git/mediawiki'],
    }
    file { '/srv/git/mediawiki/skins':
        ensure  => directory,
        require => File['/srv/git/mediawiki'],
    }

    git::clone { 'mediawiki/core':
        directory => '/srv/git/mediawiki/core.git',
        bare      => true,
        require   => File['/srv/git/mediawiki'],
    }

    systemd::timer::job { 'mediawiki-core':
        ensure      => absent,
        description => 'Regular jobs to update gitcache for mediawiki/core',
        user        => 'root',
        command     => '/usr/bin/git -C /srv/git/mediawiki/core.git fetch origin --prune +refs/heads/*:refs/heads/*',
        interval    => {'start' => 'OnCalendar', 'interval' => '*-*-* 3:00:00'},
        require     => Git::Clone['mediawiki/core'],
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

    git::clone { 'mediawiki/extensions/Cite':
        directory => '/srv/git/mediawiki/extensions/Cite.git',
        bare      => true,
        require   => File['/srv/git/mediawiki/extensions'],
    }

    git::clone { 'mediawiki/extensions/cldr':
        directory => '/srv/git/mediawiki/extensions/cldr.git',
        bare      => true,
        require   => File['/srv/git/mediawiki/extensions'],
    }

    git::clone { 'mediawiki/extensions/Echo':
        directory => '/srv/git/mediawiki/extensions/Echo.git',
        bare      => true,
        require   => File['/srv/git/mediawiki/extensions'],
    }

    git::clone { 'mediawiki/extensions/EventLogging':
        directory => '/srv/git/mediawiki/extensions/EventLogging.git',
        bare      => true,
        require   => File['/srv/git/mediawiki/extensions'],
    }

    git::clone { 'mediawiki/extensions/MobileFrontend':
        directory => '/srv/git/mediawiki/extensions/MobileFrontend.git',
        bare      => true,
        require   => File['/srv/git/mediawiki/extensions'],
    }

    git::clone { 'mediawiki/extensions/Scribunto':
        directory => '/srv/git/mediawiki/extensions/Scribunto.git',
        bare      => true,
        require   => File['/srv/git/mediawiki/extensions'],
    }

    git::clone { 'mediawiki/extensions/TemplateData':
        directory => '/srv/git/mediawiki/extensions/TemplateData.git',
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

    git::clone { 'mediawiki/skins/MinervaNeue':
        directory => '/srv/git/mediawiki/skins/MinervaNeue.git',
        bare      => true,
        require   => File['/srv/git/mediawiki/skins'],
    }

    git::clone { 'mediawiki/skins/Vector':
        directory => '/srv/git/mediawiki/skins/Vector.git',
        bare      => true,
        require   => File['/srv/git/mediawiki/skins'],
    }
}
