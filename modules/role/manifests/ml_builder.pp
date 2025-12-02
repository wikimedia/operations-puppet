# SPDX-License-Identifier: Apache-2.0

class role::ml_builder {
  include profile::base::production
  include profile::firewall

  include profile::amd_gpu
#   TODO: add build-specific profiles here
}
