# == Class: profile::apifeatureusage::logstash
#
# Loads api-feature-usage logs into ElasticSearch for
# MediaWiki Extension:ApiFeatureUsage
#
class profile::apifeatureusage::logstash (
  Array[Stdlib::Host]        $targets                              = lookup('profile::apifeatureusage::logstash::targets'),
  Hash                       $curator_actions                      = lookup('profile::apifeatureusage::logstash::curator_actions'),
  Hash[String, String]       $input_kafka_ssl_truststore_passwords = lookup('profile::apifeatureusage::logstash::input_kafka_ssl_truststore_passwords'),
  Optional[String]           $input_kafka_consumer_group_id        = lookup('profile::apifeatureusage::logstash::input_kafka_consumer_group_id', { default_value => undef }),
  Optional[Stdlib::Fqdn]     $jobs_host                            = lookup('profile::apifeatureusage::logstash::jobs_host',                     { default_value => undef }),
  Stdlib::Port               $jmx_exporter_port                    = lookup('profile::apifeatureusage::logstash::jmx_exporter_port',             { default_value => 7800  }),
  Optional[Stdlib::Unixpath] $java_home                            = lookup('profile::apifeatureusage::logstash::java_home',                     { default_value => undef }),
) {
  require ::profile::java

  class { 'elasticsearch::curator': }

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

  sysctl::parameters { 'logstash_receive_skbuf':
    values => {
      'net.core.rmem_default' => 8388608,
    },
  }

  $apt_component = 'elastic710'
  apt::repository { 'wikimedia-elastic':
    uri        => 'http://apt.wikimedia.org/wikimedia',
    dist       => "${::lsbdistcodename}-wikimedia",
    components => "thirdparty/${apt_component}",
    before     => Class['::logstash'],
  }

  class { '::logstash':
    jmx_exporter_port   => $jmx_exporter_port,
    jmx_exporter_config => $jmx_exporter_config_file,
    pipeline_workers    => $::processorcount * 2,
    java_package        => 'openjdk-11-jdk',
    logstash_package    => 'logstash-oss',
    logstash_version    => 7,
    log_format          => 'json',
    gc_log              => false,
    java_home           => pick($java_home, $profile::java::default_java_home),
    manage_service      => false,
  }

  systemd::service { 'logstash':
      ensure   => present,
      content  => init_template('logstash', 'systemd_override'),
      override => true,
      restart  => true,
  }

  # Ship logstash service logs to ELK
  rsyslog::input::file { 'logstash-json':
    path => '/var/log/logstash/logstash-json.log'
  }

  # Inputs
  logstash::input::kafka { 'rsyslog-udp-localhost-eqiad':
    kafka_cluster_name                    => 'logging-eqiad',
    topics_pattern                        => 'udp_localhost-.*',
    group_id                              => $input_kafka_consumer_group_id,
    type                                  => 'syslog',
    tags                                  => ['input-kafka-rsyslog-udp-localhost', 'rsyslog-udp-localhost', 'kafka'],
    codec                                 => 'json',
    security_protocol                     => 'SSL',
    ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-eqiad'],
    ssl_endpoint_identification_algorithm => '',
    consumer_threads                      => 3,
  }

  logstash::input::kafka { 'rsyslog-udp-localhost-codfw':
    kafka_cluster_name                    => 'logging-codfw',
    topics_pattern                        => 'udp_localhost-.*',
    group_id                              => $input_kafka_consumer_group_id,
    type                                  => 'syslog',
    tags                                  => ['input-kafka-rsyslog-udp-localhost', 'rsyslog-udp-localhost', 'kafka'],
    codec                                 => 'json',
    security_protocol                     => 'SSL',
    ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-codfw'],
    ssl_endpoint_identification_algorithm => '',
    consumer_threads                      => 3,
  }

  # Filters
  file { '/etc/logstash/conf.d':
    ensure  => directory,
    source  => 'puppet:///modules/profile/apifeatureusage/filters',
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0440',
    recurse => true,
    purge   => true,
    force   => true,
    notify  => Service['logstash'],
  }

  # Outputs
  $targets.each |Stdlib::Host $cluster| {
    logstash::output::elasticsearch { "apifeatureusage-${cluster}":
      host            => $cluster,
      index           => 'apifeatureusage-%{+YYYY.MM.dd}',
      guard_condition => '[type] == "api-feature-usage-sanitized"',
      priority        => 95,
      document_type   => '_doc',
      require         => File['/etc/logstash/templates'],
    }

    # Curator
    $dc = $cluster.split('[.]')[-2]
    $cluster_name = "production-search-${dc}"
    $curator_hosts = [$cluster]
    $http_port = 9200
    if $jobs_host == $::fqdn {
      elasticsearch::curator::config { $cluster_name:
        content => template('elasticsearch/curator_cluster.yaml.erb'),
      }

      elasticsearch::curator::job { "apifeatureusage_${dc}":
        cluster_name => $cluster_name,
        actions      => $curator_actions,
      }
    } else {
      elasticsearch::curator::job { "apifeatureusage_${dc}":
        ensure       => 'absent',
        cluster_name => $cluster_name,
      }
    }
  }

  # Templates
  file { '/etc/logstash/templates':
    ensure  => directory,
    source  => 'puppet:///modules/profile/apifeatureusage/templates',
    owner   => 'logstash',
    group   => 'logstash',
    mode    => '0444',
    recurse => true,
    purge   => true,
    force   => true,
    notify  => Service['logstash'],
  }
}
