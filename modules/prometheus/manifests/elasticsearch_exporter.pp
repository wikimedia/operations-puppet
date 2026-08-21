define prometheus::elasticsearch_exporter(
    Stdlib::Port          $prometheus_port,
    Stdlib::Host          $elasticsearch_host,
    Stdlib::Port          $elasticsearch_port,
    Enum['http', 'https'] $elasticsearch_scheme,
    String                $extra_config = '',
) {
  include ::prometheus::elasticsearch_exporter::common

  $es_uri = "${elasticsearch_scheme}://${elasticsearch_host}:${elasticsearch_port}"
  systemd::service { "prometheus-elasticsearch-exporter-${elasticsearch_port}":
    ensure         => present,
    content        => systemd_template('prometheus-elasticsearch-exporter'),
    require        => Package['prometheus-elasticsearch-exporter'],
    service_params => {
      ensure => 'running',
    }
  }

  $service_name = "prometheus-elasticsearch-exporter-${elasticsearch_port}"
  profile::auto_restarts::service { $service_name: }
}
