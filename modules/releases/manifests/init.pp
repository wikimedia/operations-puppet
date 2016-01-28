# Release server module for Wikimedia
#
# this module sets up a simple web server
# that will serve static files
#
# production: https://releases.wikimedia.org
#
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
        $server_admin = 'noc@wikimedia.org',
) {

    ensure_resource('file', '/srv/org', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia', {'ensure' => 'directory' })
    ensure_resource('file', '/srv/org/wikimedia/releases', {'ensure' => 'directory' })

    include ::apache::mod::rewrite
    include ::apache::mod::headers

    apache::site { $sitename:
        content => template('releases/apache.conf.erb'),
    }

    file { '/srv/org/wikimedia/releases/releases-header.html':
        ensure => 'present',
        mode   => '0444',
        owner  => 'www-data',
        group  => 'www-data',
        source => 'puppet:///modules/releases/releases-header.html',
    }

    # T94486
    package { 'phpunit':
        ensure => present,
    }
}
