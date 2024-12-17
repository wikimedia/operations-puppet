# SPDX-License-Identifier: Apache-2.0

# Return the configured Prometheus instances
function prometheus::instances (
) {
  include prometheus::instances
  $prometheus::instances::config
}
