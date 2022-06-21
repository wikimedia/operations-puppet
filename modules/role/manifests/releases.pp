# == Class: role::releases
#
# this role sets up a simple web server
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

class role::releases {

    system::role { 'releases':
        ensure      => 'present',
        description => 'Wikimedia Software Releases Server',
    }

    include profile::base::production
    include profile::base::firewall
    include profile::backup::host
    include profile::releases::common
    include profile::releases::mediawiki
    include profile::docker::ferm
    include profile::kubernetes::deployment_server
    include profile::releases::mediawiki::private
    include profile::releases::mediawiki::security
    include profile::releases::mwcli
    include profile::releases::parsoid
    include profile::releases::blubber
    include profile::releases::wikibase
    include profile::tlsproxy::envoy # TLS termination
}
