# SPDX-License-Identifier: Apache-2.0
# Temporary role to migrate to bookworm instalation

class role::puppetboard::bookworm {
    system::role { 'puppetboard::bookworm': description => 'Puppetboard server' }

    include role::puppetboard
}
