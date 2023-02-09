# SPDX-License-Identifier: Apache-2.0
#
# @summary Shared profile for the production-specific setup parts of front- and back-end puppetmasters.
#
class profile::puppetmaster::production {
    # Starting with git 2.30.3 (which also got backported to older releases
    # as CVE-2022-24765) git changed the default behaviour to add an ownership
    # check which prevents git operations by a user different than the one which
    # owns the .git directory within the repository.
    # This also applies to the root user, add the safe.directory directive:
    # https://github.com/git/git/commit/8959555cee7ec045958f9b6dd62e541affb7e7d9

    git::systemconfig { 'safe.directory-labs-private':
        settings => {
            'safe' => {
                'directory' => '/var/lib/git/labs/private',
            }
        }
    }

    git::systemconfig { 'safe.directory-operations-puppet':
        settings => {
            'safe' => {
                'directory' => '/var/lib/git/operations/puppet',
            }
        }
    }

    git::systemconfig { 'safe.directory-operations-private':
        settings => {
            'safe' => {
                'directory' => '/var/lib/git/operations/private',
            }
        }
    }

    git::systemconfig { 'safe.directory-srv-private':
        settings => {
            'safe' => {
                'directory' => '/srv/private',
            }
        }
    }

    git::systemconfig { 'safe.directory-netbox-hiera':
        settings => {
            'safe' => {
                'directory' => '/srv/netbox-hiera',
            }
        }
    }
}
