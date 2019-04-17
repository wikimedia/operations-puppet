# == Class profile::eventschemas::repositories
#
# Clones all the provided event schema repositories using the eventschemas::repository define.
#
# == Parameters
#
# [*repositories*]
#   Hash of repository $name -> git origin.
#   Each of these will be cloned at /srv/schema/repositories/$name
#   Default: { mediawiki => mediawiki/eventschemas }
#
class profile::eventschemas::repositories(
    $repositories = hiera('profile::eventschemas::repositories', {'mediawiki' => 'mediawiki/eventschemas'})
) {
    keys($repositories).each |String $name| {
        eventschemas::repository { $name:
            origin => $repositories[$name]
        }
    }
}
