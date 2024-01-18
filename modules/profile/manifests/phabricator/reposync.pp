# SPDX-License-Identifier: Apache-2.0
# phabricator - repo syncing between servers
# temporary test
class profile::phabricator::reposync {

    if $::fqdn in ['phab2002.codfw.wmnet', 'gitlab2003.wikimedia.org'] {
        rsync::quickdatacopy { 'phabricator-repos-test':
            ensure      => present,
            auto_sync   => false,
            delete      => true,
            source_host => 'phab2002.codfw.wmnet',
            dest_host   => 'gitlab2003.wikimedia.org',
            module_path => '/srv/repos',
        }
    }

}
