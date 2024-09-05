# SPDX-License-Identifier: Apache-2.0

# Generate blackbox modules configuration from service::catalog entries.
# The main use case is to have customised modules for HTTP(s) services.
class prometheus::blackbox::modules::service_catalog (
  Hash[String, Wmflib::Service] $services_config,
) {
  $modules = $services_config.reduce({}) |$memo, $el| {
    $service_name = $el[0]
    $service_config = $el[1]

    $module_options = wmflib::service::probe::module_options($service_name, $service_config)

    if 'probes' in $service_config {
      # XXX support more than one probe if/when needed
      $probe = $service_config['probes'][0]
      if $probe['type'] == 'http' {
        $http_options = wmflib::service::probe::http_module_options($service_name, $service_config)

        $service_modules = {
          "http_${service_name}_ip4" => {
            'prober' => 'http',
            'http'   => {
              'preferred_ip_protocol' => 'ip4',
            } + $http_options,
          } + $module_options,
          "http_${service_name}_ip6" => {
            'prober' => 'http',
            'http'   => {
              'preferred_ip_protocol' => 'ip6',
            } + $http_options,
          } + $module_options,
        }
      } elsif $probe['type'] =~ /^tcp/ {
        $tcp_options = wmflib::service::probe::tcp_module_options($service_name, $service_config)
        $service_modules = {
          "tcp_${service_name}_ip4" => {
            'prober' => 'tcp',
            'tcp'   => {
              'preferred_ip_protocol' => 'ip4',
            } + $tcp_options,
          } + $module_options,
          "tcp_${service_name}_ip6" => {
            'prober' => 'tcp',
            'tcp'   => {
              'preferred_ip_protocol' => 'ip6',
            } + $tcp_options,
          } + $module_options,
        }
      } else {
        # Unknown probe type
        $service_modules = {}
      }
    } else {
      $service_modules = {}
    }

    if !empty($service_modules) {
      $memo + $service_modules
    } else {
      $memo
    }
  }

  prometheus::blackbox::module { 'service_catalog':
    content => to_yaml({'modules' => $modules}),
  }
}
