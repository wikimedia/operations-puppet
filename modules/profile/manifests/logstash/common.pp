# SPDX-License-Identifier: Apache-2.0
# vim:sw=4 ts=4 sts=4 et:
# profile::logstash::common
#
# Common Logstash resources shared amongst all clusters.
#
class profile::logstash::common (
  OpenSearch::InstanceParams $dc_settings       = lookup('profile::opensearch::dc_settings'),
  Stdlib::Port               $jmx_exporter_port = lookup('profile::logstash::collector::jmx_exporter_port', { 'default_value' => 7800 }),
  Optional[Stdlib::Unixpath] $java_home         = lookup('profile::logstash::java_home',                    { 'default_value' => undef }),
) {

  require ::profile::java

  $config_dir = '/etc/prometheus'
  $jmx_exporter_config_file = "${config_dir}/logstash_jmx_exporter.yaml"

  # Prometheus JVM metrics
  profile::prometheus::jmx_exporter { "logstash_collector_${::hostname}":
    hostname    => $::hostname,
    port        => $jmx_exporter_port,
    config_file => $jmx_exporter_config_file,
    config_dir  => $config_dir,
    source      => 'puppet:///modules/profile/logstash/jmx_exporter.yaml',
  }

  # Ship logstash service logs to ELK
  rsyslog::input::file { 'logstash-json':
    path => '/var/log/logstash/logstash-json.log'
  }

  # Install Logstash
  class { '::logstash':
    jmx_exporter_port   => $jmx_exporter_port,
    jmx_exporter_config => $jmx_exporter_config_file,
    pipeline_workers    => $::processorcount * 2,
    manage_service      => false,
    log_format          => 'json',
    enable_dlq          => true,
    dlq_hosts           => $dc_settings['cluster_hosts'],
    java_package        => 'openjdk-11-jdk',
    logstash_package    => 'logstash-oss',
    logstash_version    => 7,
    gc_log              => false,
    java_home           => pick($java_home, $profile::java::default_java_home),
  }

  package { 'logstash-plugins':
    ensure  => present,
    require => Package['logstash']
  }

  sysctl::parameters { 'logstash_receive_skbuf':
    values => {
      'net.core.rmem_default' => 8388608,
    },
  }

  # Logstash will prevent shutdown indefinitely if OpenSearch is stopped before it.
  # Set systemd ordering to manage logstash after OS startup and before OS shutdown
  $systemd_after = "opensearch_1@${dc_settings['cluster_name']}"
  systemd::service { 'logstash':
    ensure   => present,
    content  => init_template('logstash', 'systemd_override'),
    override => true,
    restart  => true,
  }

  # Filter Configuration Directory
  file { '/etc/logstash/conf.d':
    ensure  => directory,
    source  => 'puppet:///modules/profile/logstash/filters',
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0440',
    recurse => true,
    purge   => true,
    force   => true,
    notify  => Service['logstash'],
  }

  # Custom Filter Scripts Directory
  file { '/etc/logstash/filter_scripts':
    ensure  => directory,
    source  => 'puppet:///modules/profile/logstash/filter_scripts',
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0444',
    recurse => true,
    purge   => true,
    force   => true,
    notify  => Service['logstash'],
  }

  # Index Templates Directory
  file { '/etc/logstash/templates':
    ensure  => directory,
    source  => 'puppet:///modules/profile/logstash/templates',
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0444',
    recurse => true,
    purge   => true,
    force   => true,
  }

}
