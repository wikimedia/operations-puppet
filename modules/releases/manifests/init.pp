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
#
# Because this service is intended to live behind a
# caching cluster which would handle ssl/tls, it does not
# install certs or configure apache for ssl/tls

class releases (
        $sitename = undef,
        $sitename_jenkins = undef,
        $server_admin = 'noc@wikimedia.org',
) {

    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia/releases', {'ensure' => 'directory' })

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
        group   => 'releasers-mediawiki',
        require => File['/srv/org/wikimedia/releases'],
    }

    include ::apache::mod::rewrite
    include ::apache::mod::headers
    include ::apache::mod::proxy
    include ::apache::mod::proxy_http

    apache::site { $sitename:
        content => template('releases/apache.conf.erb'),
    }

    apache::site { $sitename_jenkins:
        content => template('releases/apache-jenkins.conf.erb'),
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

    # T94486
    package { 'phpunit':
        ensure => present,
    }
}
