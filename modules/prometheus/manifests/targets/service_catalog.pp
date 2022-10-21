# SPDX-License-Identifier: Apache-2.0

# Read $services_config and generate Prometheus targets in $targets_file for
# all services with addresses within $networks.

# $service_ips_override is the single IP all services will point to when
# specified. Used in testing environments.

define prometheus::targets::service_catalog (
  Hash[String, Wmflib::Service] $services_config,
  String $targets_file,
  Array $networks,
  Optional[Stdlib::IP::Address] $service_ips_override = undef,
) {
  # Iterate over services
  $targets = $services_config.reduce([]) |$memo, $el| {
    $service_name = $el[0]
    $service_config = $el[1]

    $all_ips = wmflib::service::get_ips_for_services($service_name => $service_config, $::site)
    $network_ips = filter($all_ips) |$addr| { stdlib::ip_in_range($addr, $networks) }

    if length($network_ips) > 0 and $service_ips_override {
      $service_ips = [ $service_ips_override ]
    } else {
      $service_ips = $network_ips
    }

    # Iterate over this service's probes and collect targets.
    $probes = $service_config['probes'].reduce([]) |$memo, $probe| {

      # Iterate over addresses
      $probe_targets = $service_ips.reduce([]) |$memo, $addr| {
        $memo + wmflib::service::probe::targets(
          $service_name,
          $service_config,
          $probe,
          $addr,
        )
      }

      $memo + $probe_targets
    }

    $memo + $probes
  }

  file { $targets_file:
    content => to_yaml($targets),
  }
}
