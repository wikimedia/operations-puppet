# SPDX-License-Identifier: Apache-2.0
# == Class profile::analytics::refinery_git_config
#
# Starting with git 2.30.3 (which also got backported to older releases
# as CVE-2022-24765) git changed the default behaviour to add an ownership
# check which prevents git operations by a user different than the one which
# owns the .git directory within the repository.
# This also applies to the root user, add the safe.directory directive:
# https://github.com/git/git/commit/8959555cee7ec045958f9b6dd62e541affb7e7d9
#
# To propagate the Refinery deploy into HDFS a secondary deployment step is
# made outside of the regular Scap deploy. This process and the script in
# use (refinery-deploy-to-hdfs) run git commands, so add a safe.directory
# override for the refinery and refinery-cache deploy directories.
#
class profile::analytics::refinery_git_config () {
    git::systemconfig { 'safe.directory-refinery-deploy':
        settings => {
            'safe' => {
                'directory' => '/srv/deployment/analytics/refinery',
            }
        }
    }
    git::systemconfig { 'safe.directory-refinery-cache-deploy':
        settings => {
            'safe' => {
                'directory' => '/srv/deployment/analytics/refinery-cache',
            }
        }
    }
}
