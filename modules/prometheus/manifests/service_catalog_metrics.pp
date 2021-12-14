# service_catalog_info{service="foo:443", state="bar"} 1
class prometheus::service_catalog_metrics (
  Hash[String, Wmflib::Service] $services_config,
  Stdlib::Absolutepath $outfile,
) {

  # Iterate over services
  $state_by_service = $services_config.reduce({}) |$memo, $el| {
    $service_name = $el[0]
    $service_config = $el[1]

    $port = $service_config['port']

    $memo.merge({
      "${service_name}:${port}" => $service_config['state']
    })
  }

  file { $outfile:
    content => template('prometheus/service_catalog_metrics.prom.erb'),
  }
}
