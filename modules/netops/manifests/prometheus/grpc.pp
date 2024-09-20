# SPDX-License-Identifier: Apache-2.0

# Instruct Prometheus to check gRPC on $targets

# $targets is the map of devices to target
# $targets_file is the path to write the result to
# $extra_labels is an hash to labels to attach to each target,
# in addition to labels derived from the config (address family, address, etc)


define netops::prometheus::grpc (
  Hash[String[3], Netbox::Device::Network] $targets,
  String $targets_file,
  Hash[String, String] $extra_labels = {},
) {
  $out = $targets.reduce([]) |$memo, $el| {
    $config = $el[1]

    $grpc_port = $config['manufacturer'] ? {
      sonic => 8080,
      default => 32767,
    }

    if 'primary_fqdn' in $config {
      $fqdn = $config['primary_fqdn']
      $extra_config = {
        targets => [ "${fqdn}:${grpc_port}" ],
        labels => {
          module => 'grpc_connect',
          role   => $config['role'],
        } + $extra_labels,
      }
    } else {
      $extra_config = {}
    }

    $memo + [$extra_config]
  }

  file { $targets_file:
    content => to_yaml(flatten($out)),
  }
}

