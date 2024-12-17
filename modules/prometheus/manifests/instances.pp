# SPDX-License-Identifier: Apache-2.0

# Return the authoritative configuration for Prometheus instances.
# Take into account hiera values and overrides as follows:
# * prometheus::instances_defaults  provides defaults for instance parameters
# * prometheus::instances           maps instance -> instance-specific parameters
# * prometheus::instances_overrides if set, will override any settings from above.
#                                   Used in testing environments to e.g. set smaller retention size

class prometheus::instances {
    $defaults  = lookup('prometheus::instances_defaults')  # lint:ignore:wmf_styleguide
    $instances = lookup('prometheus::instances')  # lint:ignore:wmf_styleguide
    $override = lookup('prometheus::instances_overrides', { 'default_value' => {} })  # lint:ignore:wmf_styleguide

    $config = $instances.reduce({}) | $memo, $data | {
      $i_name = $data[0]
      $i_aux = { 'targets_path' => "/srv/prometheus/${i_name}/targets", 'instance' => $i_name }
      $i_config = deep_merge($defaults, $data[1], $i_aux, $override)
      $memo + { $i_name => $i_config }
    }
}
