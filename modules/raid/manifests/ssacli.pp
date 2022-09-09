# SPDX-License-Identifier: Apache-2.0
# HP Raid controller
class raid::ssacli {
    # backwards compatibility for facter['raid_mgmt_tools'] == ssacli
    include raid::hpsa::ssacli
}
