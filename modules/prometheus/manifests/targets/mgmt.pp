# SPDX-License-Identifier: Apache-2.0

# Read $targets with mgmt hostnames (from netbox-hiera) and generate
# Prometheus targets in $targets_file.

define prometheus::targets::mgmt (
  Hash $targets,
  String $targets_file,
  Hash[String, String] $extra_labels = {},
) {
  $out = $targets.reduce([]) |$memo, $el| {
    $mgmt_fqdn = $el[0]
    $config = $el[1]

    $fqdn_parts = split($mgmt_fqdn, '[.]')
    $instance = join($fqdn_parts[0, 2], '.')

    $ip4 = {
      # Relabeling will make sure to put everything up to "@"
      # in the "instance" label and use the rest as the target
      # for blackbox exporter to use.
      targets => ["${instance}:22@${mgmt_fqdn}:22"],
      labels  => {
        module      => 'ssh_banner',
        rack        => $config['rack'],
      } + $extra_labels,
    }

    $memo + [$ip4]
  }

  file { $targets_file:
    content => to_yaml(flatten($out)),
  }
}
