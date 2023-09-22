# SPDX-License-Identifier: Apache-2.0
# Temporary role to migrate to bookworm instalation

class role::puppetdb::bookworm {
    system::role { 'puppetdb::bookworm': description => 'Puppetdb server' }

    include role::puppetdb
    include profile::sre::os_updates
}
