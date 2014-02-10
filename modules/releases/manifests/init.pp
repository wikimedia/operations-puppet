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
# - the /srv/org/wikimedia/releases docroot
# - users and groups access to add content
#
# Because this service is intended to live behind a
# caching cluster which would handle ssh, it does not
# install certs or configure apache for ssh

class releases {

    system::role { 'releases': description => 'Releases webserver' }

    include 'releases::webserver'
    include 'releases::backups'
    include 'releases::monitor'

    releases::access { 'brion': group => 'mobileupld' }
    releases::access { 'csteipp': group => 'mwupld' }
}
