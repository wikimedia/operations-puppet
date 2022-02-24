# Return the service probes configuration as expected by network probes jobs.

function wmflib::service::probe::targets(
  String $service_name,
  Wmflib::Service $service_config,
  Wmflib::Service::Probe $probe,
  Stdlib::IP::Address $address,
) >> Array[Hash] {
  $af = $address ? {
    Stdlib::IP::Address::V4 => 'ip4',
    Stdlib::IP::Address::V6 => 'ip6',
  }
  $port = $service_config['port']
  $common_labels = {
    'address' => $address,
    'family'  => $af,
  }

  if $probe['type'] == 'http' {
    $path = pick($probe['path'], '/')

    $scheme = $service_config['encryption'] ? {
      false   => 'http',
      default => 'https',
    }

    $probes = [
      {
        'labels'  => $common_labels + { 'module' => "http_${service_name}_${af}" },
        'targets' => [ "${service_name}:${port}@${scheme}://[${address}]:${port}${path}" ],
      },
    ]
  }

  if $probe['type'] == 'tcp' or $probe['type'] == 'tcp-notls' {
    # Auto-detect TLS from service configuration, and force-disable
    # when tcp-notls is used.
    $module = $service_config['encryption'] ? {
      false   => "tcp_${af}",
      default => $probe['type'] == 'tcp-notls' ? {
        true    => "tcp_${af}",
        default => "tcp_tls_${af}",
      }
    }

    $probes = [
      {
        'labels'  => $common_labels + { 'module' => $module },
        'targets' => [ "${service_name}:${port}@[${address}]:${port}" ],
      },
    ]
  }

  return flatten($probes)
}
