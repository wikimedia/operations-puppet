# SPDX-License-Identifier: Apache-2.0
# A place to temp. dump gitlab backups until T274463 is resolved
class profile::gitlab::dump {

        rsync::quickdatacopy { 'gitlab-backups':
            source_host         => 'gitlab1001.wikimedia.org',
            dest_host           => 'gitlab1004.wikimedia.org',
            auto_sync           => false,
            module_path         => '/srv/gitlab-backup',
            server_uses_stunnel => true,
        }
}
