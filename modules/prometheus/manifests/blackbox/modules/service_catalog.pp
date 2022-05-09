# Generate blackbox modules configuration from service::catalog entries.
# The main use case is to have customised modules for HTTP(s) services.
class prometheus::blackbox::modules::service_catalog (
  Hash[String, Wmflib::Service] $services_config,
) {
  $modules = $services_config.reduce({}) |$memo, $el| {
    $service_name = $el[0]
    $service_config = $el[1]

    $http_options = wmflib::service::probe::http_module_options($service_name, $service_config)

    $module_options = wmflib::service::probe::module_options($service_name, $service_config)

    $memo + {
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
  }

  file { '/etc/prometheus/blackbox.yml.d/service_catalog.yml':
    content => to_yaml({'modules' => $modules}),
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
    notify  => Exec['assemble blackbox.yml'],
  }
}
