# SPDX-License-Identifier: Apache-2.0
# Format and mount an unattched cinder volume
#
class profile::labs::cindermount::srv {
    cinderutils::ensure { 'cinder_on_srv':
        mount_point => '/srv',
        min_gb      => 3,
    }
}
