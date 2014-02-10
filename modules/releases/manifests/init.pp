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
# caching cluster which would handle ssh, it does not
# install certs or configure apache for ssh

class releases (
        $sitename = undef,
        $docroot = undef,
        $server_admin = 'noc@wikimedia.org',
) {

    class { 'releases::webserver':
        sitename     => $sitename,
        docroot      => $docroot,
        server_admin => $server_admin,
    }

    include 'releases::backups'
}
