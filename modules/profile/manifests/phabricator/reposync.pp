# SPDX-License-Identifier: Apache-2.0
# phabricator - repo syncing between servers
# temporary test
class profile::phabricator::reposync {

    if $::fqdn in ['phab2002.codfw.wmnet', 'people1004.eqiad.wmnet'] {
        rsync::quickdatacopy { 'phabricator-repos-test':
            ensure      => present,
            auto_sync   => false,
            delete      => true,
            source_host => 'phab2002.codfw.wmnet',
            dest_host   => 'people1004.eqiad.wmnet',
            module_path => '/srv/repos',
        }
    }

}
