# SPDX-License-Identifier: Apache-2.0

class profile::openstack::base::puppetmaster::safe_dirs () {
    # Git defaults to preventing multiple users from messing with the
    # a directory, but for us that's a feature more than a security risk.
    #
    # T325128, T325280

    git::systemconfig { 'allow multiple local git users in labs/private':
        settings => {
            'safe' => {
                'directory' => '/var/lib/git/labs/private',
            }
        }
    }
    git::systemconfig { 'allow multiple local git users in operations/puppet':
        settings => {
            'safe' => {
                'directory' => '/var/lib/git/operations/puppet',
            }
        }
    }
}
