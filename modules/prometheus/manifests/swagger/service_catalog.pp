# SPDX-License-Identifier: Apache-2.0

# Generate targets for swagger_exporter checks.
define prometheus::swagger::service_catalog (
  Hash[String, Wmflib::Service] $services,
  Stdlib::Unixpath              $targets_path
) {
  $targets = $services.reduce([]) |$memo, $el| {
    $service_name = $el[0]
    $service_config = $el[1]
    $swagger_probes = $service_config['probes'].filter |$item| { $item['type'] == 'swagger' }
    $scheme = $service_config['encryption'] ? {
      true    => 'https',
      default => 'http',
    }

    # there should only be one swagger probe per service
    $probe_config = $swagger_probes[0]
    $memo + [{
      'targets' => [
        "${scheme}://${service_name}.svc.${::site}.wmnet:${service_config['port']}"
      ]
    }]
  }
  file { "${targets_path}/swagger_${title}.yaml":
    ensure  => absent,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => to_yaml($targets),
  }
}
