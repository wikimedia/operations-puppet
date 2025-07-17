# SPDX-License-Identifier: Apache-2.0

# Return the configured Prometheus/thanos instances
function metamonitoring::expected_instances (
) {
  include metamonitoring::expected_instances
  $metamonitoring::expected_instances::monitored_instances
}
