define prometheus::elasticsearch_exporter(
    Stdlib::Port $prometheus_port,
    Stdlib::Port $elasticsearch_port,
) {
  include ::prometheus::elasticsearch_exporter::common

  $es_uri = "http://localhost:${elasticsearch_port}"
  systemd::service { "prometheus-elasticsearch-exporter-${elasticsearch_port}":
    ensure         => present,
    content        => systemd_template('prometheus-elasticsearch-exporter'),
    require        => Package['prometheus-elasticsearch-exporter'],
    service_params => {
      ensure => 'running',
    }
  }
}
