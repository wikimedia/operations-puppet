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

    $addresses = dnsquery::lookup($host, true)
    if $addresses.empty() {
      fail("netops::prometheus::hosts: no addresses found for '${host}'")
    }

    $probes = $addresses.map |$ip| {
      $family = wmflib::ip_family($ip)

      $ret = {
        targets => ["${host}:0@${ip}"],
        labels  => {
          module      => "icmp_ip${family}",
          family      => "ip${family}",
          address     => $ip,
          realm       => $config['realm'],
          rack        => $config['rack'],
          role        => 'host',
          # Not strictly required, but make sure all metrics (in this job)
          # have the same set of labels.
          target_site => $config['site'],
        } + $extra_labels,
      }

      $ret
    }

    $memo + $probes
  }

  file { $targets_file:
    content => to_yaml(flatten($out)),
  }
}
