# Release server module for Wikimedia
#
# this module sets up a simple web server
# that will serve static files
#
# production: https://releases.wikimedia.org
# jenkins:    https://releases-jenkins.wikimedia.org
# requirements:
#
# - initial content must be manually copied into
#   /srv/org/wikimedia/releases
# - ownership/perms of subdirs must be initially
#   be set appropriately for users to add content
#
# this sets up:
#
# - the apache site config
# - the /srv/org/wikimedia/ subdir docroot
# - a Jenkins instance for automated MW releases
# - another separate apache site for jenkins UI
#
# Because this service is intended to live behind a
# caching cluster which would handle ssl/tls, it does not
# install certs or configure apache for ssl/tls

class releases (
    Optional[String] $sitename = undef,
    Optional[String] $sitename_jenkins = undef,
    String $server_admin = 'noc@wikimedia.org',
    Stdlib::Unixpath $prefix = '/',
    Stdlib::Port $http_port = '8080',
) {

    ensure_resource('file', '/srv/mediawiki', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/patches', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia/releases', {'ensure' => 'directory' })

    git::clone { 'mediawiki/core':
        directory => '/srv/mediawiki/core',
        require   => File['/srv/mediawiki'],
        bare      => true,
    }
    git::clone { 'mediawiki/tools/release':
        ensure    => 'latest',
        directory => '/srv/mediawiki/release-tools',
        require   => File['/srv/mediawiki'],
    }

    file { '/srv/org/wikimedia/releases/mediawiki':
        ensure  => 'directory',
        mode    => '2775',
        owner   => 'root',
        group   => 'releasers-mediawiki',
        require => File['/srv/org/wikimedia/releases'],
    }

    file { '/srv/org/wikimedia/releases/wikidiff2':
        ensure  => 'directory',
        mode    => '2775',
        owner   => 'root',
        group   => 'releasers-wikidiff2',
        require => File['/srv/org/wikimedia/releases'],
    }

    file { '/srv/org/wikimedia/releases/releases-header.html':
        ensure => 'present',
        mode   => '0444',
        owner  => 'www-data',
        group  => 'www-data',
        source => 'puppet:///modules/releases/releases-header.html',
    }

    file { '/srv/org/wikimedia/releases/mediawiki/releases-header-mw.html':
        ensure => 'present',
        mode   => '0444',
        owner  => 'www-data',
        group  => 'www-data',
        source => 'puppet:///modules/releases/releases-header-mw.html',
    }

    git::clone { 'operations/deployment-charts':
        ensure    => 'latest',
        directory => '/srv/deployment-charts',
    }

    file { '/srv/org/wikimedia/releases/charts':
        ensure  => 'link',
        target  => '/srv/deployment-charts/charts',
        require =>  Git::Clone['operations/deployment-charts'],
    }

    # T94486
    package { 'phpunit':
        ensure => present,
    }

    package { 'php-curl':
        ensure => present,
    }
}
