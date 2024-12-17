# SPDX-License-Identifier: Apache-2.0

# Return $instance configuration to use with prometheus::server
function prometheus::instance_config (
  String $instance,
) {
  include prometheus::instances
  $prometheus::instances::config[$instance]
}
