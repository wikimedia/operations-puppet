# SPDX-License-Identifier: Apache-2.0
# vim:sw=4 ts=4 sts=4 et:
# == Class: profile::logstash::collector7
#
# Provisions Logstash and an Elasticsearch node to proxy requests to ELK stack
# Elasticsearch cluster.
#
# == Parameters:
# - $input_kafka_ssl_truststore_passwords:
#   Hash of kafka cluster name to password for jks truststore used by logstash kafka input plugin,
#   e.g. $input_kafka_ssl_truststore_passwords['logging-eqiad'] == 'XXXXXX', etc.
#
class profile::logstash::collector7 (
    Hash[String, String] $input_kafka_ssl_truststore_passwords = lookup('profile::logstash::collector::input_kafka_ssl_truststore_passwords'),
    Optional[String] $input_kafka_consumer_group_id = lookup('profile::logstash::collector::input_kafka_consumer_group_id', {'default_value' => undef}),
    Stdlib::Port $jmx_exporter_port = lookup('profile::logstash::collector::jmx_exporter_port', {'default_value' => 7800}),
    Array[Stdlib::Host] $maintenance_hosts = lookup('maintenance_hosts', {'default_value' => []}),
    Elasticsearch::InstanceParams $dc_settings = lookup('profile::elasticsearch::dc_settings'),
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

    class { '::logstash':
        jmx_exporter_port   => $jmx_exporter_port,
        jmx_exporter_config => $jmx_exporter_config_file,
        pipeline_workers    => $::processorcount * 2,
        manage_service      => false,
        log_format          => 'json',
        enable_dlq          => true,
        dlq_hosts           => $dc_settings['cluster_hosts'],
    }

    sysctl::parameters { 'logstash_receive_skbuf':
        values => {
            'net.core.rmem_default' => 8388608,
        },
    }

    systemd::service { 'logstash':
        ensure   => present,
        content  => init_template('logstash', 'systemd_override'),
        override => true,
        restart  => true,
    }

    ## Inputs (10)

    ferm::service { 'grafana_dashboard_definition_storage':
        proto  => 'tcp',
        port   => '9200',
        srange => '@resolve((grafana1002.eqiad.wmnet))',
    }

    $maintenance_hosts_str = join($maintenance_hosts, ' ')
    ferm::service { 'logstash_canary_checker_reporting':
        proto  => 'tcp',
        port   => '9200',
        srange => "(\$DEPLOYMENT_HOSTS ${maintenance_hosts_str})",
    }

    logstash::input::dlq { 'main': }

    # Logstash collectors in both sites pull messages
    # from logging kafka clusters in both DCs.
    logstash::input::kafka { 'rsyslog-shipper-eqiad':
        kafka_cluster_name                    => 'logging-eqiad',
        topics_pattern                        => 'rsyslog-.*',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'syslog',
        tags                                  => ['input-kafka-rsyslog-shipper', 'rsyslog-shipper', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-eqiad'],
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'rsyslog-shipper-codfw':
        kafka_cluster_name                    => 'logging-codfw',
        topics_pattern                        => 'rsyslog-.*',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'syslog',
        tags                                  => ['rsyslog-shipper','kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-codfw'],
        ssl_endpoint_identification_algorithm => '',
    }

    logstash::input::kafka { 'rsyslog-udp-localhost-eqiad':
        kafka_cluster_name                    => 'logging-eqiad',
        topics_pattern                        => 'udp_localhost-.*',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'syslog',
        tags                                  => ['input-kafka-rsyslog-udp-localhost', 'rsyslog-udp-localhost', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-eqiad'],
        ssl_endpoint_identification_algorithm => '',
    }

    logstash::input::kafka { 'rsyslog-udp-localhost-codfw':
        kafka_cluster_name                    => 'logging-codfw',
        topics_pattern                        => 'udp_localhost-.*',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'syslog',
        tags                                  => ['rsyslog-udp-localhost','kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-codfw'],
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'rsyslog-logback-eqiad':
        kafka_cluster_name                    => 'logging-eqiad',
        topics_pattern                        => 'logback.*',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'logback',
        tags                                  => ['input-kafka-rsyslog-logback', 'kafka-logging-eqiad', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-eqiad'],
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'deprecated-eqiad':
        kafka_cluster_name                    => 'logging-eqiad',
        topics_pattern                        => 'deprecated.*',
        group_id                              => $input_kafka_consumer_group_id,
        tags                                  => ['input-kafka-deprecated', 'kafka-logging-eqiad', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-eqiad'],
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'rsyslog-logback-codfw':
        kafka_cluster_name                    => 'logging-codfw',
        topics_pattern                        => 'logback.*',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'logback',
        tags                                  => ['input-kafka-rsyslog-logback', 'kafka-logging-codfw', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-codfw'],
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'clienterror-eqiad':
        kafka_cluster_name                    => 'logging-eqiad',
        topics_pattern                        => 'eqiad\.mediawiki\.client\.error|eqiad\.kaios_app\.error',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'clienterror',
        tags                                  => ['input-kafka-clienterror-eqiad', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-eqiad'],
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'clienterror-codfw':
        kafka_cluster_name                    => 'logging-codfw',
        topics_pattern                        => 'codfw\.mediawiki\.client\.error|codfw\.kaios_app\.error',
        group_id                              => $input_kafka_consumer_group_id,
        type                                  => 'clienterror',
        tags                                  => ['input-kafka-clienterror-codfw', 'kafka', 'es'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-codfw'],
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'networkerror-eqiad':
        kafka_cluster_name                    => 'logging-eqiad',
        topic                                 => 'eqiad.w3c.reportingapi.network_error',
        group_id                              => $input_kafka_consumer_group_id,
        tags                                  => ['input-kafka-networkerror-eqiad', 'kafka', 'throttle-exempt'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-eqiad'],
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    logstash::input::kafka { 'networkerror-codfw':
        kafka_cluster_name                    => 'logging-codfw',
        topic                                 => 'codfw.w3c.reportingapi.network_error',
        group_id                              => $input_kafka_consumer_group_id,
        tags                                  => ['input-kafka-networkerror-codfw', 'kafka', 'throttle-exempt'],
        codec                                 => 'json',
        security_protocol                     => 'SSL',
        ssl_truststore_password               => $input_kafka_ssl_truststore_passwords['logging-codfw'],
        ssl_endpoint_identification_algorithm => '',
        consumer_threads                      => 3,
    }

    # Collect all EventGate instance error.validation topics into logstash.
    # Maps logstash::input::kafka title to a kafka cluster and topic to consume.
    $eventgate_validation_error_logstash_inputs = {

        # eventgate-main uses both Kafka main-eqiad and main-codfw
        'eventgate-main-validation-error-eqiad' => {
            'kafka_cluster_name' => 'main-eqiad',
            'topic' => 'eqiad.eventgate-main.error.validation'
        },
        'eventgate-main-validation-error-codfw' => {
            'kafka_cluster_name' => 'main-codfw',
            'topic' => 'codfw.eventgate-main.error.validation'
        },

        # eventgate-analytics uses only Kafka jumbo-eqiad
        'eventgate-analytics-validation-error-eqiad' => {
            'kafka_cluster_name' => 'jumbo-eqiad',
            'topic' => 'eqiad.eventgate-analytics.error.validation'
        },
        'eventgate-analytics-validation-error-codfw' => {
            'kafka_cluster_name' => 'jumbo-eqiad',
            'topic' => 'codfw.eventgate-analytics.error.validation'
        },

        # eventgate-analytics-external uses only Kafka jumbo-eqiad
        'eventgate-analytics-external-validation-error-eqiad' => {
            'kafka_cluster_name' => 'jumbo-eqiad',
            'topic' => 'eqiad.eventgate-analytics-external.error.validation'
        },
        'eventgate-analytics-external-validation-error-codfw' => {
            'kafka_cluster_name' => 'jumbo-eqiad',
            'topic' => 'codfw.eventgate-analytics-external.error.validation'
        },

        # eventgate-logging-external uses both Kafka logging-eqiad and logging-codfw
        'eventgate-logging-external-validation-error-eqiad' => {
            'kafka_cluster_name' => 'logging-eqiad',
            'topic' => 'eqiad.eventgate-logging-external.error.validation'
        },
        'eventgate-logging-external-validation-error-codfw' => {
            'kafka_cluster_name' => 'logging-codfw',
            'topic' => 'codfw.eventgate-logging-external.error.validation'
        },
    }
    $eventgate_validation_error_logstash_inputs.each |String $input_title, $input_params| {
        logstash::input::kafka { $input_title:
            kafka_cluster_name                    => $input_params['kafka_cluster_name'],
            topic                                 => $input_params['topic'],
            group_id                              => $input_kafka_consumer_group_id,
            type                                  => 'eventgate_validation_error',
            tags                                  => ["input-kafka-${input_title}", 'kafka', 'es', 'eventgate'],
            codec                                 => 'json',
            security_protocol                     => 'SSL',
            ssl_truststore_password               => $input_kafka_ssl_truststore_passwords[$input_params['kafka_cluster_name']],
            ssl_endpoint_identification_algorithm => '',
            consumer_threads                      => 3,
        }
    }

    # TODO: Rename this, this is the EventLogging event error topic input.
    $kafka_topic_eventlogging        = 'eventlogging_EventError'
    logstash::input::kafka { $kafka_topic_eventlogging:
        kafka_cluster_name                    => 'jumbo-eqiad',
        topic                                 => $kafka_topic_eventlogging,
        group_id                              => $input_kafka_consumer_group_id,
        tags                                  => [$kafka_topic_eventlogging, 'kafka', 'input-kafka-eventlogging', 'es'],
        type                                  => 'eventlogging',
        codec                                 => 'json',
        ssl_endpoint_identification_algorithm => '',
    }

    ## Global pre-processing (15)

    # move files into module?
    # lint:ignore:puppet_url_without_modules
    file { '/etc/logstash/conf.d':
      ensure  => directory,
      source  => 'puppet:///modules/profile/logstash/filters',
      owner   => 'logstash',
      group   => 'logstash',
      mode    => '0440',
      recurse => true,
      purge   => true,
      force   => true,
    }

    file { '/etc/logstash/filter_scripts':
        ensure  => directory,
        source  => 'puppet:///modules/profile/logstash/filter_scripts',
        owner   => 'logstash',
        group   => 'logstash',
        mode    => '0444',
        recurse => true,
        purge   => true,
        force   => true,
    }

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
    # lint:endignore

    ## Outputs (90)
    logstash::output::elasticsearch { 'logstash':
        host            => '127.0.0.1',
        guard_condition => '"es" in [tags] and ![ecs]',
        index           => '%{[@metadata][index_name]}-%{+YYYY.MM.dd}',
        priority        => 90,
        template        => '/etc/logstash/templates/logstash_7.0-1.json',
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
    $ecs_versions = {
        # version => revision
        '1.7.0'  => '5',
        '1.11.0' => '2'
    }
    $ecs_versions.each |String $ecs_version, String $ecs_revision| {
        logstash::output::elasticsearch { "ecs_${ecs_version}-${ecs_revision}":
          host            => '127.0.0.1',
          guard_condition => "\"es\" in [tags] and [ecs][version] == \"${ecs_version}\"",
          index           => "ecs-${ecs_version}-${ecs_revision}-%{[@metadata][partition]}-%{+xxxx.ww}",
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
          index           => "w3creportingapi-${w3creportingapi_version}-${w3creportingapi_revision}-%{+xxxx.ww}",
          priority        => 90,
          template        => "/etc/logstash/templates/w3creportingapi_${w3creportingapi_version}-${w3creportingapi_revision}.json",
          require         => File['/etc/logstash/templates'],
        }
    }

    logstash::output::elasticsearch { 'dlq-1.0.0-1':
      host            => '127.0.0.1',
      guard_condition => '[type] == "dlq"',
      index           => 'dlq-1.0.0-1-%{+YYYY.MM.dd}',
      priority        => 90,
      template        => '/etc/logstash/templates/dlq_1.0.0-1.json',
      require         => File['/etc/logstash/templates'],
    }

    # TODO: cleanup -- T256418
    package { 'prometheus-statsd-exporter':
        ensure => 'absent'
    }

    # Ship logstash service logs to ELK
    rsyslog::input::file { 'logstash-json':
        path => '/var/log/logstash/logstash-json.log'
    }

    # TODO: cleanup -- T277080
    mtail::program { 'logstash':
        ensure => absent,
        notify => Service['mtail'],
        source => 'puppet:///modules/mtail/programs/logstash.mtail',
    }
}
