# SPDX-License-Identifier: Apache-2.0

# Generate a list of targets suitable for Prometheus blackbox. Similar
# to netops::blackbox::icmp but tailored for hosts as opposed to network
# devices.

# $targets is the map of hosts to target
# $targets_file is the path to write the result to
# $extra_labels is an hash to labels to attach to each target,
# in addition to labels derived from the config (address family, address, etc)

define netops::prometheus::hosts (
  Prometheus::Blackbox::SmokeHosts $targets,
  String $targets_file,
  Hash[String, String] $extra_labels = {},
) {
  $out = $targets.reduce([]) |$memo, $el| {
    $host = $el[0]
    $config = $el[1]

    $v4_address = ipresolve($host, 4)

    $ip4 = {
      targets => ["${host}:0@${v4_address}"],
      labels  => {
        module      => 'icmp_ip4',
        family      => 'ip4',
        address     => $v4_address,
        realm       => $config['realm'],
        rack        => $config['rack'],
        role        => 'host',
        # Not strictly required, but make sure all metrics (in this job)
        # have the same set of labels.
        target_site => $config['site'],
      } + $extra_labels,
    }

    $memo + [$ip4]
  }

  file { $targets_file:
    content => to_yaml(flatten($out)),
  }
}
