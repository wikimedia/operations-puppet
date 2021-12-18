# vim:sw=4 ts=4 sts=4 et:
# == Class: profile::logstash::beta
#
# Provisions a Logstash collector instance for the beta environment
#
class profile::logstash::beta (
  Hash[String, String] $input_kafka_ssl_truststore_passwords = lookup('profile::logstash::collector::input_kafka_ssl_truststore_passwords'),
  String               $input_kafka_consumer_group_id        = lookup('profile::logstash::collector::input_kafka_consumer_group_id', { 'default_value' => 'logstash' }),
) {

  # The environment certificate authority is tied to the environment's puppetmaster.
  # Until this is no longer the case, don't overwrite the truststore.
  $manage_truststore = false

  # Allow API access to LABS_NETWORKS via ferm, but control access via "scap-access" security group.
  # Will be obseleted by T216141.
  ferm::service { 'opensearch-labs-9200':
    proto   => 'tcp',
    port    => 9200,
    notrack => true,
    srange  => '$LABS_NETWORKS',
  }

  include profile::logstash::common

  # Custom Filters and Overrides
  file { '/etc/logstash/conf.d/11-filter_spam.conf':
    ensure  => 'present',
    mode    => '0440',
    owner   => 'logstash',
    group   => 'logstash',
    notify  => Service['logstash'],
    content => '
filter {
  # DLQ mitigations in deployment-prep environment appear broken.
  if [loggerName] == "org.logstash.common.io.DeadLetterQueueWriter" {
    drop { id => "filter/drop/spam/dead_letter_queue_errors" }
  }
}
    '
  }

  # Inputs (10)
  logstash::input::dlq { 'main': }

  # Logstash collectors in both sites pull messages
  # from logging kafka clusters in both DCs.
  logstash::input::kafka { 'rsyslog-shipper-eqiad':
    kafka_cluster_name                    => 'logging-beta',
    topics_pattern                        => 'rsyslog-.*',
    group_id                              => $input_kafka_consumer_group_id,
    type                                  => 'syslog',
    tags                                  => ['input-kafka-rsyslog-shipper', 'rsyslog-shipper', 'kafka', 'es'],
    codec                                 => 'json',
    security_protocol                     => 'SSL',
    ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-beta'],
    ssl_endpoint_identification_algorithm => '',
    consumer_threads                      => 3,
    manage_truststore                     => $manage_truststore,
  }

  logstash::input::kafka { 'rsyslog-udp-localhost-eqiad':
    kafka_cluster_name                    => 'logging-beta',
    topics_pattern                        => 'udp_localhost-.*',
    group_id                              => $input_kafka_consumer_group_id,
    type                                  => 'syslog',
    tags                                  => ['input-kafka-rsyslog-udp-localhost', 'rsyslog-udp-localhost', 'kafka', 'es'],
    codec                                 => 'json',
    security_protocol                     => 'SSL',
    ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-beta'],
    ssl_endpoint_identification_algorithm => '',
    manage_truststore                     => $manage_truststore,
  }

  logstash::input::kafka { 'rsyslog-logback-eqiad':
    kafka_cluster_name                    => 'logging-beta',
    topics_pattern                        => 'logback.*',
    group_id                              => $input_kafka_consumer_group_id,
    type                                  => 'logback',
    tags                                  => ['input-kafka-rsyslog-logback', 'kafka-logging-beta', 'kafka', 'es'],
    codec                                 => 'json',
    security_protocol                     => 'SSL',
    ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-beta'],
    ssl_endpoint_identification_algorithm => '',
    consumer_threads                      => 3,
    manage_truststore                     => $manage_truststore,
  }

  logstash::input::kafka { 'deprecated-eqiad':
    kafka_cluster_name                    => 'logging-beta',
    topics_pattern                        => 'deprecated.*',
    group_id                              => $input_kafka_consumer_group_id,
    tags                                  => ['input-kafka-deprecated', 'kafka-logging-beta', 'kafka', 'es'],
    codec                                 => 'json',
    security_protocol                     => 'SSL',
    ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-beta'],
    ssl_endpoint_identification_algorithm => '',
    consumer_threads                      => 3,
    manage_truststore                     => $manage_truststore,
  }

  logstash::input::kafka { 'clienterror-eqiad':
    kafka_cluster_name                    => 'logging-beta',
    topics_pattern                        => 'eqiad\.mediawiki\.client\.error|eqiad\.kaios_app\.error',
    group_id                              => $input_kafka_consumer_group_id,
    type                                  => 'clienterror',
    tags                                  => ['input-kafka-clienterror-eqiad', 'kafka', 'es'],
    codec                                 => 'json',
    security_protocol                     => 'SSL',
    ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-beta'],
    ssl_endpoint_identification_algorithm => '',
    consumer_threads                      => 3,
    manage_truststore                     => $manage_truststore,
  }

  logstash::input::kafka { 'networkerror-eqiad':
    kafka_cluster_name                    => 'logging-beta',
    topic                                 => 'eqiad.w3c.reportingapi.network_error',
    group_id                              => $input_kafka_consumer_group_id,
    tags                                  => ['input-kafka-networkerror-eqiad', 'kafka', 'throttle-exempt'],
    codec                                 => 'json',
    security_protocol                     => 'SSL',
    ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-beta'],
    ssl_endpoint_identification_algorithm => '',
    consumer_threads                      => 3,
    manage_truststore                     => $manage_truststore,
  }

  # Outputs (90)
  # logstash-* indexes output
  logstash::output::elasticsearch { 'logstash':
    host            => '127.0.0.1',
    guard_condition => '"es" in [tags] and ![ecs]',
    index           => '%{[@metadata][index_name]}-%{+YYYY.MM.dd}',
    priority        => 90,
    template        => '/etc/logstash/templates/logstash_7.0-1.json',
    require         => File['/etc/logstash/templates'],
  }

  # dlq-* indexes output
  logstash::output::elasticsearch { 'dlq-1.0.0-1':
    host            => '127.0.0.1',
    guard_condition => '[type] == "dlq"',
    index           => 'dlq-1.0.0-1-%{+YYYY.MM.dd}',
    priority        => 90,
    template        => '/etc/logstash/templates/dlq_1.0.0-1.json',
    require         => File['/etc/logstash/templates'],
  }

  # Generate a logstash output for each supported version.
  #
  # Installing a new template requires a new index in order for the changes to take effect.
  # Depending on the index pattern rotation schedule, the new index could take an inordinate amount
  # of time to actually rotate.  With a "%{YYYY.MM.dd}" date pattern, this means
  # rotation occurs each day at 00:00 UTC.
  # The concept of revision here works around this constraint to facilitate a shortened
  # "deploy to observable effects" turnaround time and does not restrict us to frequent index rotations.
  #
  # Expects a template file conforming to "ecs_<VERSION>-<REVISION>.json" in "profile/files/logstash/templates/"
  # The most recently built template can be found here: https://doc.wikimedia.org/ecs/#downloads
  $ecs_versions = {
    # version => revision
    '1.7.0'  => '5',
    '1.11.0' => '2'
  }
  $ecs_versions.each |String $ecs_version, String $ecs_revision| {
    logstash::output::elasticsearch { "ecs_${ecs_version}-${ecs_revision}":
      host            => '127.0.0.1',
      guard_condition => "\"es\" in [tags] and [ecs][version] == \"${ecs_version}\"",
      index           => "ecs-${ecs_version}-${ecs_revision}-%{[@metadata][partition]}-%{+YYYY.ww}",
      priority        => 90,
      template        => "/etc/logstash/templates/ecs_${ecs_version}-${ecs_revision}.json",
      require         => File['/etc/logstash/templates'],
    }
  }

  $w3creportingapi_versions = {
    # version => revision
    '1.0.0' => '2'
  }
  $w3creportingapi_versions.each |String $w3creportingapi_version, String $w3creportingapi_revision| {
    logstash::output::elasticsearch { "w3creportingapi-${w3creportingapi_version}-${w3creportingapi_revision}":
      host            => '127.0.0.1',
      guard_condition => "[\$schema] == \"/w3c/reportingapi/network_error/${w3creportingapi_version}\"",
      index           => "w3creportingapi-${w3creportingapi_version}-${w3creportingapi_revision}-%{+YYYY.ww}",
      priority        => 90,
      template        => "/etc/logstash/templates/w3creportingapi_${w3creportingapi_version}-${w3creportingapi_revision}.json",
      require         => File['/etc/logstash/templates'],
    }
  }

}
