# Read service::catalog entries and generate suitable Prometheus target files
# for blackbox exporter.

class prometheus::service_catalog_targets (
  Hash[String, Wmflib::Service] $services_config,
  String $targets_path,
  Hash[String, Stdlib::IP::Address::V4] $service_ips_override = {},
) {
  # Iterate over services
  $targets = $services_config.reduce([]) |$memo, $el| {
    $service_name = $el[0]
    $service_config = $el[1]

    $scheme = $service_config['encryption'] ? {
      false   => 'http',
      default => 'https',
    }
    $port = $service_config['port']

    # Find out the service name in 'svc' zone.
    # For TLS services the blackbox exporter 'module' configuration
    # knows which SNI to send
    if 'aliases' in $service_config {
      $svc_name = $service_config['aliases'][0]
    } elsif 'discovery' in $service_config {
      $svc_name = $service_config['discovery'][0]['dnsdisc']
    } else {
      $svc_name = $service_name
    }
    $dns_name = "${svc_name}.svc.${::site}.wmnet"

    # Select the final name or address to talk to.
    #
    # For load balanced services (i.e. 'lvs' stanza is present) use the DNS
    # name in the 'svc' zone.
    # For non-lvs use the hardcoded IPs in the catalog, unless overridden
    # via $service_ips_override (e.g. for testing environments).
    if 'lvs' in $service_config {
      $name_or_address = $dns_name
    } elsif $service_name in $service_ips_override {
      $name_or_address = $service_ips_override[$service_name]
    } else {
      $service_ips = wmflib::service::get_ips_for_services($service_name => $service_config, $::site)
      $name_or_address = $service_ips[0]
    }

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
            'targets' => [ "${service_name}:${port}@${scheme}://${name_or_address}:${port}${path}" ]
          },
          {
            'labels'  => { 'module' => 'icmp_ip4' },
            'targets' => [ "${service_name}:${port}@${name_or_address}" ]
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
