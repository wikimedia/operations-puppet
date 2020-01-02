# == Class profile::eventschemas::repositories
#
# Clones all the provided event schema repositories using the eventschemas::repository define.
#
# == Parameters
#
# [*repositories*]
#   Hash of repository $name -> git origin.
#   Each of these will be cloned at /srv/schema/repositories/$name
#   Default: {
#       'primary'   => 'schemas/event/primary',
#       'secondary' => 'schemas/event/secondary',
#       'mediawiki' => 'mediawiki/event-schemas'
#   }
#
class profile::eventschemas::repositories(
    $repositories = hiera('profile::eventschemas::repositories', {
        'primary'   => 'schemas/event/primary',
        'secondary' => 'schemas/event/secondary',
        # mediawiki/event-schemas is being deprecated in favor of schemas/event/primary
        'mediawiki' => 'mediawiki/event-schemas',
    })
) {
    keys($repositories).each |String $name| {
        eventschemas::repository { $name:
            origin => $repositories[$name]
        }
    }
}
