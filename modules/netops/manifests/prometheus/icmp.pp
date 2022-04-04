# SPDX-License-Identifier: Apache-2.0

# Instruct Prometheus to ping $targets

# $targets is the map of devices to target
# $targets_file is the path to write the result to
# $extra_labels is an hash to labels to attach to each target,
# in addition to labels derived from the config (address family, address, etc)
define netops::prometheus::icmp (
  Wmflib::Infra::Devices $targets,
  String $targets_file,
  Hash[String, String] $extra_labels = {},
) {

  $out = $targets.reduce([]) |$memo, $el| {
    $name = $el[0]
    $config = $el[1]

    if 'ipv4' in $config {
      $v4_address = $config['ipv4']
      $ip4 = {
        targets => [ "${name}:0@${v4_address}" ],
        labels => {
          module      => 'icmp_ip4',
          family      => 'ip4',
          target_site => $config['site'],
          role        => $config['role'],
          address     => $v4_address
        } + $extra_labels,
      }
    } else {
      $ip4 = {}
    }

    if 'ipv6' in $config {
      $v6_address = $config['ipv6']
      $ip6 = {
        targets => [ "${name}:0@${v6_address}" ],
        labels => {
          module      => 'icmp_ip6',
          family      => 'ip6',
          target_site => $config['site'],
          role        => $config['role'],
          address     => $v6_address
        } + $extra_labels,
      }
    } else {
      $ip6 = {}
    }

    $memo + [$ip4, $ip6]
  }

  file { $targets_file:
    content => to_yaml(flatten($out)),
  }
}

