class prometheus::service_catalog_targets (
  Hash[String, Wmflib::Service] $services_config,
  String $targets_path,
) {

  # Iterate over services
  $targets = $services_config.reduce([]) |$memo, $el| {
    $service_name = $el[0]
    $service_config = $el[1]

    $scheme = $service_config['encryption'] ? {
      false   => 'http',
      default => 'https',
    }
    $module_tls = $service_config['encryption'] ? {
      false   => '',
      default => 'tls_',
    }
    $port = $service_config['port']
    # Use the first discovery name for probing
    $discovery_name = $service_config['discovery'][0]['dnsdisc']

    # Iterate over this service's probes and collect targets
    $probes = $service_config['probes'].reduce([]) |$memo, $el| {
      if $el['type'] == 'http' {
        $path = $el['path'] ? {
          undef   => '/',
          default => $el['path'],
        }

        $res = [
          {
            'labels'  => { 'module' => "http_${service_name}_ip4" },
            'targets' => [ "${service_name}:${port}@${scheme}://${discovery_name}.discovery.wmnet:${port}${path}" ]
          },
          {
            'labels'  => { 'module' => "tcp_${module_tls}ip4" },
            'targets' => [ "${service_name}:${port}@${discovery_name}.discovery.wmnet:${port}" ]
          },
          {
            'labels'  => { 'module' => 'icmp_ip4' },
            'targets' => [ "${service_name}:${port}@${discovery_name}.discovery.wmnet" ]
          },
        ]
      }

      $memo + $res
    }

    $memo + $probes
  }

  file { "${targets_path}/blackbox_discovery.yaml":
    content => ordered_yaml($targets),
  }
}
