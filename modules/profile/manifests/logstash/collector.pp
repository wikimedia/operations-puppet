# SPDX-License-Identifier: Apache-2.0
# vim:sw=4 ts=4 sts=4 et:
# == Class: profile::logstash::collector
#
# Provisions Logstash and an Elasticsearch node to proxy requests to ELK stack
# Elasticsearch cluster.
#
# == Parameters:
# - $input_kafka_ssl_truststore_passwords:
#   Hash of kafka cluster name to password for jks truststore used by logstash kafka input plugin,
#   e.g. $input_kafka_ssl_truststore_passwords['logging-eqiad'] == 'XXXXXX', etc.
#
class profile::logstash::collector (
    Hash[String, String] $input_kafka_ssl_truststore_passwords = lookup('profile::logstash::collector::input_kafka_ssl_truststore_passwords'),
    Optional[String] $input_kafka_consumer_group_id = lookup('profile::logstash::collector::input_kafka_consumer_group_id', {'default_value' => undef}),
    Stdlib::Port $jmx_exporter_port = lookup('profile::logstash::collector::jmx_exporter_port', {'default_value' => 7800}),
    Array[Stdlib::Host] $maintenance_hosts = lookup('maintenance_hosts', {'default_value' => []}),
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
    }

    sysctl::parameters { 'logstash_receive_skbuf':
        values => {
            'net.core.rmem_default' => 8388608,
        },
    }

    ## Inputs (10)

    logstash::input::udp2log { 'mediawiki':
        port => 8324,
        tags => ['input-udp2log-mediawiki-8324'],
    }

    ferm::service { 'logstash_udp2log':
        proto   => 'udp',
        port    => '8324',
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }

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

    logstash::input::gelf { 'gelf':
        port => 12201,
        tags => ['input-gelf-12201', 'deprecated-input'],
    }

    ferm::service { 'logstash_gelf':
        proto   => 'udp',
        port    => '12201',
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }

    logstash::input::udp { 'logback':
        port  => 11514,
        codec => 'json',
        tags  => ['input-udp-logback-11514'],
    }

    ferm::service { 'logstash_udp':
        proto   => 'udp',
        port    => '11514',
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }

    logstash::input::tcp { 'json_lines':
        port  => 11514,
        codec => 'json_lines',
        tags  => ['input-tcp-json_lines-11514'],
    }

    ferm::service { 'logstash_json_lines':
        proto   => 'tcp',
        port    => '11514',
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }
    nrpe::monitor_service { 'logstash_json_lines_tcp':
        description  => 'logstash JSON linesTCP port',
        nrpe_command => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 11514',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Logstash',
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

    # Drop ECS messages on the legacy cluster
    logstash::conf { 'filter_ecs':
      source   => 'puppet:///modules/profile/logstash/drop_ecs.conf',
      priority => 17
    }

    # disable 15-filter_ulogd_ecs.conf
    file { '/etc/logstash/conf.d/15-filter_ulogd_ecs.conf':
      ensure  => 'present',
      content => '',
      owner   => 'logstash',
      group   => 'logstash',
      mode    => '0440',
      notify  => Service['logstash'],
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

    # Restore ApiFeatureUsage functionality
    logstash::input::kafka { 'rsyslog-udp-localhost-eqiad':
        kafka_cluster_name      => 'logging-eqiad',
        topics_pattern          => 'udp_localhost-.*',
        group_id                => $input_kafka_consumer_group_id,
        type                    => 'syslog',
        tags                    => ['input-kafka-rsyslog-udp-localhost', 'rsyslog-udp-localhost', 'kafka'],
        codec                   => 'json',
        security_protocol       => 'SSL',
        ssl_truststore_password => $input_kafka_ssl_truststore_passwords['logging-eqiad'],
    }

    logstash::input::kafka { 'rsyslog-udp-localhost-codfw':
        kafka_cluster_name      => 'logging-codfw',
        topics_pattern          => 'udp_localhost-.*',
        group_id                => $input_kafka_consumer_group_id,
        type                    => 'syslog',
        tags                    => ['rsyslog-udp-localhost', 'kafka'],
        codec                   => 'json',
        security_protocol       => 'SSL',
        ssl_truststore_password => $input_kafka_ssl_truststore_passwords['logging-codfw'],
        consumer_threads        => 3,
    }

    # Output logs tagged "deprecated-input" to eqiad Kafka for ingest by elk7.
    # These are logs that have arrived via a "legacy" (non-kafka) logstash input.
    # The elk7 cluster ingests via Kafka only.
    $kafka_config_eqiad = kafka_config('logging-eqiad')
    logstash::output::kafka{ 'deprecated':
        guard_condition         => '"deprecated-input" in [tags] and "es" in [tags]',
        codec                   => 'json',
        priority                => 90,
        bootstrap_servers       => $kafka_config_eqiad['brokers']['ssl_string'],
        ssl_truststore_location => '/etc/logstash/kafka-logging-truststore-eqiad.jks',
        ssl_truststore_password => $input_kafka_ssl_truststore_passwords['logging-eqiad'],
    }

    # TODO: cleanup -- T256418
    package { 'prometheus-statsd-exporter':
        ensure => 'absent'
    }

    # Ship logstash server logs to ELK using startmsg_regex pattern to join multi-line events based on datestamp
    # example: [2018-11-30T16:13:48,043]
    rsyslog::input::file { 'logstash-multiline':
        path           => '/var/log/logstash/logstash-plain.log',
        startmsg_regex => '^\\\\[[0-9,-\\\\ \\\\:]+\\\\]',
    }

    mtail::program { 'logstash':
        ensure => present,
        notify => Service['mtail'],
        source => 'puppet:///modules/mtail/programs/logstash.mtail',
    }
}
