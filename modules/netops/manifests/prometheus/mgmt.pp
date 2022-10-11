# SPDX-License-Identifier: Apache-2.0

# Generate a list of targets suitable for Prometheus blackbox. Similar
# to netops::blackbox::host but tailored to pick one mgmt target per rack.

# $targets is the map of hosts to target
# $targets_file is the path to write the result to
# $extra_labels is an hash to labels to attach to each target,
# in addition to labels derived from the config (address family, address, etc)

define netops::prometheus::mgmt (
  Hash $targets,
  String $targets_file,
  Hash[String, String] $extra_labels = {},
) {
  # Invert $targets to get a rack -> host (singular) hash
  $rack_to_target = Hash(
    $targets.map |$k, $v| { [ $v['rack'], $k ] }
  )

  $out = $rack_to_target.reduce([]) |$memo, $el| {
    $rack = $el[0]
    $target = $el[1]

    $v4_address = ipresolve($target, 4)

    $ip4 = {
      targets => [$target],
      labels  => {
        module      => 'icmp_ip4',
        family      => 'ip4',
        address     => $v4_address,
        rack        => $rack,
        role        => 'mgmt',
      } + $extra_labels,
    }

    $memo + [$ip4]
  }

  file { $targets_file:
    content => to_yaml(flatten($out)),
  }
}
