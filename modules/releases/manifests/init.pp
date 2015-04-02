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
        $docroot = undef,
        $server_admin = 'noc@wikimedia.org',
) {
    file { '/srv/org':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { '/srv/org/wikimedia':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }
    file { "/srv/org/wikimedia/${docroot}":
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    include 'webserver::apache'
    include ::apache::mod::rewrite
    @webserver::apache::site { $sitename:
        docroot      => "/srv/org/wikimedia/${docroot}/",
        server_admin => $server_admin,
        require      => [
            Class['::apache::mod::rewrite'],
            File['/srv/org/wikimedia/releases']
        ],
    }

    # T94486
    package { 'phpunit':
        ensure => present,
    }
}
