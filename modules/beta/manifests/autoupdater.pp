# == Class: beta::autoupdater
#
# For host continuously updating MediaWiki core and extensions on the beta
# cluster. This is the lame way to automatically pull any code merged in master
# branches.
class beta::autoupdater {
    $stage_dir = '/srv/mediawiki-staging'

    file { '/usr/local/bin/wmf-beta-autoupdate.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => Package['git'],
        content => template('beta/wmf-beta-autoupdate.py.erb'),
    }

    file { '/usr/local/bin/wmf-beta-mwconfig-update':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        require => [
            Package['git'],
            File['/etc/profile.d/mediawiki.sh']
        ],
        source  => 'puppet:///modules/beta/wmf-beta-mwconfig-update',
    }

    file { '/usr/local/bin/wmf-beta-update-databases.py':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/beta/wmf-beta-update-databases.py',
    }

    git::clone { 'beta-mediawiki-core':
        directory => "${stage_dir}/php-master",
        origin    => 'https://gerrit.wikimedia.org/r/mediawiki/core.git',
        branch    => 'master',
        owner     => 'jenkins-deploy',
        group     => 'wikidev',
        require   => Git::Clone['operations/mediawiki-config'],
    }

    git::clone { 'beta-portal':
        directory => "${stage_dir}/portal-master",
        origin    => 'https://gerrit.wikimedia.org/r/wikimedia/portals.git',
        branch    => 'master',
        owner     => 'jenkins-deploy',
        group     => 'wikidev',
        require   => Git::Clone['operations/mediawiki-config'],
    }

    file { "${stage_dir}/docroot/wwwportal/portal-master":
        ensure => 'link',
        target => '../../portal-master/prod',
    }

    file { "${stage_dir}/php-master/LocalSettings.php":
        ensure  => present,
        owner   => 'jenkins-deploy',
        group   => 'wikidev',
        mode    => '0444',
        source  => 'puppet:///modules/beta/LocalSettings.php',
        require => Git::Clone['beta-mediawiki-core'],
    }

    file { "${stage_dir}/php-master/cache/l10n":
        ensure  => directory,
        owner   => 'l10nupdate',
        group   => 'wikidev',
        mode    => '0755',
        require => Git::Clone['beta-mediawiki-core'],
    }

    # Remove the placeholder extension directory of the mediawiki/core
    # checkout so that we can checkout the complete extension repository.
    exec { "/bin/rm -r ${stage_dir}/php-master/extensions":
        refreshonly => true,
        subscribe   => Git::Clone['beta-mediawiki-core'],
        before      => Git::Clone['beta-mediawiki-extensions'],
    }

    git::clone { 'beta-mediawiki-extensions':
        directory          => "${stage_dir}/php-master/extensions",
        origin             => 'https://gerrit.wikimedia.org/r/mediawiki/extensions.git',
        branch             => 'master',
        owner              => 'jenkins-deploy',
        group              => 'wikidev',
        recurse_submodules => true,
        timeout            => 1800,
        require            => Git::Clone['beta-mediawiki-core'],
    }

    # MediaWiki core has a /skins/ directory causing git clone to refuse
    # cloning mediawiki/skins.git in the existing repository. Instead use git
    # init.

    # Also hardcoded in modules/beta/templates/wmf-beta-autoupdate.py.erb
    $mw_skins_dest = "${stage_dir}/php-master/skins"

    $mw_skins_git_url = 'https://gerrit.wikimedia.org/r/mediawiki/skins.git'

    exec { 'beta_mediawiki_skins_git_init':
        command => "/usr/bin/git init ${mw_skins_dest}",
        user    => 'jenkins-deploy',
        group   => 'wikidev',
        creates => "${mw_skins_dest}/.git",
        require => Git::Clone['beta-mediawiki-core'],
        notify  => Exec['beta_mediawiki_skins_git_remote_add'],
    }
    exec { 'beta_mediawiki_skins_git_remote_add':
        command     => "/usr/bin/git remote add origin ${mw_skins_git_url}",
        user        => 'jenkins-deploy',
        group       => 'wikidev',
        cwd         => $mw_skins_dest,
        refreshonly => true,
    }

    git::clone { 'beta-mediawiki-skins':
        directory          => $mw_skins_dest,
        origin             => 'https://gerrit.wikimedia.org/r/mediawiki/skins.git',
        branch             => 'master',
        owner              => 'jenkins-deploy',
        group              => 'wikidev',
        recurse_submodules => true,
        # Needs to be initialized manually since skins dir exists
        require            => Exec['beta_mediawiki_skins_git_init'],
    }

    git::clone { 'mediawiki/vendor':
        directory => "${stage_dir}/php-master/vendor",
        branch    => 'master',
        owner     => 'jenkins-deploy',
        group     => 'wikidev',
        require   => Git::Clone['beta-mediawiki-core'],
    }
}
