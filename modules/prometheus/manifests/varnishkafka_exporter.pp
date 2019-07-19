class prometheus::varnishkafka_exporter(
  $ensure = 'present',
  $stats_default = {},
  $config = {}
) {
  # Merge safe default configuration with provided configuration
  $config_real = merge(
    {
      'stats_files'        => [],
      'required_entries'   => [],
      'num_entries_to_get' => 0,
      'stats'              => $stats_default
    },
    $config
  )

  package { 'prometheus-varnishkafka-exporter':
    ensure => 'installed'
  }

  file { '/etc/prometheus-varnishkafka-exporter.yaml':
    ensure  => 'present',
    mode    => '0444',
    content => ordered_yaml($config_real),
    require => [ Package['prometheus-varnishkafka-exporter'] ],
    notify  => [ Service['prometheus-varnishkafka-exporter'] ],
  }

  service { 'prometheus-varnishkafka-exporter':
    ensure => running,
    enable => true,
  }

  base::service_auto_restart { 'prometheus-varnishkafka-exporter': }
}
