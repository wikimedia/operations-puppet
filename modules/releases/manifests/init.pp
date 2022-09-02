# SPDX-License-Identifier: Apache-2.0
# Release server module for Wikimedia

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

    package { 'python3-pygerrit2':
        ensure => present,
    }
}
