define prometheus::elasticsearch_exporter(
    Wmflib::IpPort $prometheus_port,
    Wmflib::IpPort $elasticsearch_port,
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
