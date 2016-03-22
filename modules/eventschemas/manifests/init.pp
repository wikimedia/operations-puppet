# == Class eventschemas
# Clones the mediawiki/event-schemas repo at /srv/event-schemas.
#
# == Parameters
# [*ensure*] Passed directly to git::clone.  Default: latest.
#
class eventschemas($ensure = 'latest') {
    $path = '/srv/event-schemas'

    git::clone { 'mediawiki/event-schemas':
        ensure    => $ensure,
        directory => $path,
    }
}
