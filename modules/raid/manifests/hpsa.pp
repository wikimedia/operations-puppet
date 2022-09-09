# SPDX-License-Identifier: Apache-2.0
# HP Raid controller
class raid::hpsa {
  include raid

  if debian::codename::ge('bullseye')  {
      include raid::hpsa::ssacli
  } else {
      include raid::hpsa::hpssacli
  }
}
