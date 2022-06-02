# SPDX-License-Identifier: Apache-2.0
# HP Raid controller
class raid::ssacli {
    # backwards compatibility for facter['raid'] == ssacli
    include raid::hpsa::ssacli
}
