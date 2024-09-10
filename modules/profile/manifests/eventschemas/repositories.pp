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
class profile::eventschemas::repositories(
    Hash[String, String] $repositories = lookup('profile::eventschemas::repositories', {default_value => {
        'primary'   => 'repos/data-engineering/schemas-event-primary',
        'secondary' => 'repos/data-engineering/schemas-event-secondary',
    }})
) {
    class { '::eventschemas': }

    keys($repositories).each |String $name| {
        eventschemas::repository { $name:
            origin => $repositories[$name]
        }
    }
}
