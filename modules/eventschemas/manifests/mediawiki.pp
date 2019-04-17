# Class: eventschemas::mediawiki
#
# Class for backwards compatibility.
# Previously eventschemas init.pp did only this.
# Since we now want to support multiple repositories,
# this class is used in place of the old one.
# This should be eventually be replaced with an eventschemas::repository define
# and used out of /srv/schemas/repositories/mediawiki.
#
class eventschemas::mediawiki {
    $path = '/srv/event-schemas'

    git::clone { 'mediawiki/event-schemas':
        ensure    => 'latest',
        directory => $path,
    }
}
