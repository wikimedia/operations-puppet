# SPDX-License-Identifier: Apache-2.0

# Generate targets for swagger_exporter checks.
define prometheus::swagger::service_catalog (
  Hash[String, Wmflib::Service] $services,
  Stdlib::Unixpath              $targets_path
) {
  $targets = $services.reduce([]) |$memo, $el| {
    $service_config = $el[1]
    if 'aliases' in $service_config {
      $service_name = $service_config['aliases'][0]
    } else {
      $service_name = $el[0]
    }
    $scheme = $service_config['encryption'] ? {
      true    => 'https',
      default => 'http',
    }

    $swagger_probes = $service_config['probes'].filter |$item| { $item['type'] == 'swagger' }
    # there should only be one swagger probe per service
    $probe_config = $swagger_probes[0]

    $memo + [{
      'targets' => [
        "${scheme}://${service_name}.svc.${::site}.wmnet:${service_config['port']}"
      ]
    }]
  }
  file { "${targets_path}/swagger_${title}.yaml":
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => to_yaml($targets),
  }
}
