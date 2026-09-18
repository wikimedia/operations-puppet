# SPDX-License-Identifier: Apache-2.0
# == Class profile::eventschemas::repositories
#
# Clones all the provided event schema repositories using the eventschemas::repository define.
#
# == Parameters
#
# [*repositories*]
#   Hash of repository $name -> git origin.
#   Each of these will be cloned at /srv/eventschemas/repositories/$name
#   Default: {
#       'primary'   => 'schemas/event/primary',
#       'secondary' => 'schemas/event/secondary',
#   }
#
# [*sparse_checkouts*]
#   Hash of repository $name -> list of top-level directories to sparse
#   checkout for that repository (see eventschemas::repository). A $name
#   with no entry here gets a full checkout. Default: {
#       'mediawiki' => ['mediawiki'],
#   }
#
class profile::eventschemas::repositories(
    Hash[String, String] $repositories = lookup('profile::eventschemas::repositories', {default_value => {
        'primary'   => 'repos/data-engineering/schemas-event-primary',
        'secondary' => 'repos/data-engineering/schemas-event-secondary',
        'mediawiki' => 'repos/mediawiki/api-platform-schemas',
    }}),
    Hash[String, Array[String[1]]] $sparse_checkouts = lookup('profile::eventschemas::sparse_checkouts', {default_value => {
        'mediawiki' => ['mediawiki'],
    }}),
) {
    class { '::eventschemas': }

    keys($repositories).each |String $name| {
        eventschemas::repository { $name:
            origin       => $repositories[$name],
            sparse_paths => $sparse_checkouts[$name],
        }
    }
}
