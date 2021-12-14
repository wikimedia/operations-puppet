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

    # Find out the service name in 'svc' zone. The name is used to find which
    # IP address to talk to. For TLS services the blackbox exporter 'module'
    # configuration knows which SNI to send
    if 'aliases' in $service_config {
      $svc_name = $service_config['aliases'][0]
    } elsif 'discovery' in $service_config {
      $svc_name = $service_config['discovery'][0]['dnsdisc']
    } else {
      $svc_name = $service_name
    }
    $dns_name = "${svc_name}.svc.${::site}.wmnet"

    # Iterate over this service's probes and collect targets.
    $probes = $service_config['probes'].reduce([]) |$memo, $el| {
      if $el['type'] == 'http' {
        $path = $el['path'] ? {
          undef   => '/',
          default => $el['path'],
        }

        $res = [
          {
            'labels'  => { 'module' => "http_${service_name}_ip4" },
            'targets' => [ "${service_name}:${port}@${scheme}://${dns_name}:${port}${path}" ]
          },
          {
            'labels'  => { 'module' => "tcp_${module_tls}ip4" },
            'targets' => [ "${service_name}:${port}@${dns_name}:${port}" ]
          },
          {
            'labels'  => { 'module' => 'icmp_ip4' },
            'targets' => [ "${service_name}:${port}@${dns_name}" ]
          },
        ]
      }

      $memo + $res
    }

    # Skip services not deployed in the current site
    if $::site in $service_config['sites'] {
      $memo + $probes
    } else {
      $memo
    }
  }

  file { "${targets_path}/blackbox_discovery.yaml":
    content => ordered_yaml($targets),
  }
}
