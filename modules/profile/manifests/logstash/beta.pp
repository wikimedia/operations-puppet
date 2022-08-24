# vim:sw=4 ts=4 sts=4 et:
# == Class: profile::logstash::beta
#
# Provisions a Logstash collector instance for the beta environment
#
class profile::logstash::beta (
  Hash[String, String]   $input_kafka_ssl_truststore_passwords = lookup('profile::logstash::collector::input_kafka_ssl_truststore_passwords'),
  String                 $input_kafka_consumer_group_id        = lookup('profile::logstash::collector::input_kafka_consumer_group_id', { 'default_value' => 'logstash' }),
  Optional[Stdlib::Fqdn] $output_public_loki_host              = lookup('profile::logstash::collector::output_public_loki_host',       { 'default_value' => undef }),
) {

  # The environment certificate authority is tied to the environment's puppetmaster.
  # Until this is no longer the case, don't overwrite the truststore.
  $manage_truststore = false
  $ssl_truststore_location = '/etc/ssl/localcerts/wmf-java-cacerts'

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
    ssl_truststore_location               => $ssl_truststore_location,
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
    ssl_truststore_location               => $ssl_truststore_location,
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
    ssl_truststore_location               => $ssl_truststore_location,
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
    ssl_truststore_location               => $ssl_truststore_location,
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
    ssl_truststore_location               => $ssl_truststore_location,
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
    ssl_truststore_location               => $ssl_truststore_location,
  }

  # Outputs (90)
  # logstash-* indexes output
  logstash::output::opensearch { 'logstash':
    host            => '127.0.0.1',
    guard_condition => '[@metadata][output] == "logstash"',
    index           => 'logstash-%{[@metadata][partition]}-%{[@metadata][policy_revision]}-7.0.0-1-%{[@metadata][datestamp_format]}',
    priority        => 90,
    template        => '/etc/logstash/templates/logstash_7.0-1.json',
    require         => File['/etc/logstash/templates'],
  }

  # loki output
  if ($output_public_loki_host) {
    logstash::output::loki { 'loki_public':
      host            => $output_public_loki_host,
      guard_condition => '[@metadata][output] == "loki"',
    }
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
  #
  # Date templates for indexes use Joda Time pattern syntax (T298619):
  # https://www.joda.org/joda-time/apidocs/org/joda/time/format/DateTimeFormat.html
  #   x = weekyear
  #   Y = year of era
  #   M = month of year
  #   w = week of weekyear
  #   d = day of month
  #
  # NOTE: Week of weekyear (x) and year of era (Y) desynchronize when the new year does not fall on ISO first week [0].
  #       Only combine weekyear (x) with week of weekyear (w) when managing weekly indexes.
  #
  # [0] https://en.wikipedia.org/wiki/ISO_week_date#First_week

  $dlq_versions = {
    # version => revision
    '1.0.0' => '1'
  }
  $dlq_versions.each |String $dlq_version, String $dlq_revision| {
    logstash::output::opensearch { "dlq-${dlq_version}-${dlq_revision}":
      host            => '127.0.0.1',
      guard_condition => "[@metadata][output] == \"dlq\" and [@metadata][template_version] == \"${dlq_version}\"",
      index           => "dlq-%{[@metadata][partition]}-%{[@metadata][policy_revision]}-${dlq_version}-${dlq_revision}-%{[@metadata][datestamp_format]}",
      priority        => 90,
      template        => "/etc/logstash/templates/dlq_${dlq_version}-${dlq_revision}.json",
      require         => File['/etc/logstash/templates'],
    }
  }

  $ecs_versions = {
    # version => revision
    '1.7.0'  => '5',
    '1.11.0' => '2'
  }
  $ecs_versions.each |String $ecs_version, String $ecs_revision| {
    logstash::output::opensearch { "ecs_${ecs_version}-${ecs_revision}":
      host            => '127.0.0.1',
      guard_condition => "[@metadata][output] == \"ecs\" and [@metadata][template_version] == \"${ecs_version}\"",
      index           => "ecs-%{[@metadata][partition]}-%{[@metadata][policy_revision]}-${ecs_version}-${ecs_revision}-%{[@metadata][datestamp_format]}",
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
    logstash::output::opensearch { "w3creportingapi-${w3creportingapi_version}-${w3creportingapi_revision}":
      host            => '127.0.0.1',
      guard_condition => "[@metadata][output] == \"w3creportingapi\" and [@metadata][template_version] == \"${w3creportingapi_version}\"",
      index           => "w3creportingapi-%{[@metadata][partition]}-%{[@metadata][policy_revision]}-${w3creportingapi_version}-${w3creportingapi_revision}-%{[@metadata][datestamp_format]}",
      priority        => 90,
      template        => "/etc/logstash/templates/w3creportingapi_${w3creportingapi_version}-${w3creportingapi_revision}.json",
      require         => File['/etc/logstash/templates'],
    }
  }

}
