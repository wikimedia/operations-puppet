# vim:sw=4 ts=4 sts=4 et:
# == Class: profile::logstash::collector
#
# Provisions Logstash and an Elasticsearch node to proxy requests to ELK stack
# Elasticsearch cluster.
#
# == Parameters:
# - $statsd_host: Host to send statsd data to.
# - $prometheus_nodes: List of prometheus nodes to allow connections from
# - $input_kafka_ssl_truststore_password: password for jks truststore used by logstash kafka input plugin
#
# filtertags: labs-project-deployment-prep
class profile::logstash::collector (
    $statsd_host,
    $prometheus_nodes = hiera('prometheus_nodes', []),
    $input_kafka_ssl_truststore_password = hiera('profile::logstash::collector::input_kafka_ssl_truststore_password'),
    $input_kafka_consumer_group_id = hiera('profile::logstash::collector::input_kafka_consumer_group_id', undef),
    $jmx_exporter_port = hiera('profile::logstash::collector::jmx_exporter_port', 7800),
) {

    nrpe::monitor_service { 'logstash':
        description  => 'logstash process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u logstash -C java -a logstash',
    }

    $config_dir = '/etc/prometheus'
    $jmx_exporter_config_file = "${config_dir}/logstash_jmx_exporter.yaml"

    # Prometheus JVM metrics
    profile::prometheus::jmx_exporter { "logstash_collector_${::hostname}":
        hostname         => $::hostname,
        port             => $jmx_exporter_port,
        prometheus_nodes => $prometheus_nodes,
        config_file      => $jmx_exporter_config_file,
        config_dir       => $config_dir,
        source           => 'puppet:///modules/profile/logstash/jmx_exporter.yaml',
    }

    class { '::logstash':
        jmx_exporter_port   => $jmx_exporter_port,
        jmx_exporter_config => $jmx_exporter_config_file,
    }

    sysctl::parameters { 'logstash_receive_skbuf':
        values => {
            'net.core.rmem_default' => 8388608,
        },
    }

    ## Inputs (10)

    logstash::input::udp2log { 'mediawiki':
        port => 8324,
    }

    ferm::service { 'logstash_udp2log':
        proto   => 'udp',
        port    => '8324',
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }

    logstash::input::syslog { 'syslog':
        port => 10514,
    }

    ferm::service { 'logstash_syslog_udp':
        proto   => 'udp',
        port    => '10514',
        notrack => true,
        srange  => '($DOMAIN_NETWORKS $NETWORK_INFRA $MGMT_NETWORKS)',
    }

    ferm::service { 'logstash_syslog_tcp':
        proto   => 'tcp',
        port    => '10514',
        notrack => true,
        srange  => '($DOMAIN_NETWORKS $NETWORK_INFRA $MGMT_NETWORKS)',
    }
    nrpe::monitor_service { 'logstash_syslog_tcp':
        description  => 'logstash syslog TCP port',
        nrpe_command => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 10514',
    }

    ferm::service { 'grafana_dashboard_definition_storage':
        proto  => 'tcp',
        port   => '9200',
        srange => '@resolve(krypton.eqiad.wmnet)',
    }

    ferm::service { 'logstash_canary_checker_reporting':
        proto  => 'tcp',
        port   => '9200',
        srange => '($DEPLOYMENT_HOSTS $MAINTENANCE_HOSTS)',
    }

    logstash::input::gelf { 'gelf':
        port => 12201,
    }

    ferm::service { 'logstash_gelf':
        proto   => 'udp',
        port    => '12201',
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }

    logstash::input::log4j { 'log4j': }

    ferm::service { 'logstash_log4j':
        proto   => 'tcp',
        port    => '4560',
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }
    nrpe::monitor_service { 'logstash_log4j_tcp':
        description  => 'logstash log4j TCP port',
        nrpe_command => '/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p 4560',
    }

    logstash::input::udp { 'logback':
        port  => 11514,
        codec => 'json',
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
    }

    logstash::input::tcp { 'syslog_tls':
        type       => 'syslog',
        port       => 16514,
        ssl_enable => true,
        ssl_cert   => '/etc/logstash/ssl/cert.pem',
        ssl_key    => '/etc/logstash/ssl/server.key',
    }

    ferm::service { 'logstash_syslog_tls':
        proto   => 'tcp',
        port    => '16514',
        notrack => true,
        srange  => '$DOMAIN_NETWORKS',
    }

    $kafka_config = kafka_config("logging-${::site}")

    logstash::input::kafka { 'rsyslog-shipper':
        topics_pattern          => 'rsyslog-.*',
        group_id                => $input_kafka_consumer_group_id,
        type                    => 'syslog',
        tags                    => ['rsyslog-shipper','kafka'],
        codec                   => 'json',
        bootstrap_servers       => $kafka_config['brokers']['ssl_string'],
        security_protocol       => 'SSL',
        ssl_truststore_location => '/etc/logstash/kafka-logging-truststore.jks',
        ssl_truststore_password => $input_kafka_ssl_truststore_password,
    }

    file { '/etc/logstash/kafka-logging-truststore.jks':
        content => secret("certificates/kafka_logging-${::site}_broker/truststore.jks"),
        before  => Logstash::Input::Kafka['rsyslog-shipper'],
        owner   => 'logstash',
        group   => 'logstash',
        mode    => '0640',
    }

    # disabled for troubleshooting T193766 -herron
    monitoring::service { "${::hostname} logstash_syslog_tls":
        ensure        => absent,
        description   => 'Logstash syslog TLS listener on port 16514',
        check_command => "check_ssl_on_host_port!${::fqdn}!${::fqdn}!16514",
    }

    ## Global pre-processing (15)

    # move files into module?
    # lint:ignore:puppet_url_without_modules
    logstash::conf { 'filter_strip_ansi_color':
        source   => 'puppet:///modules/profile/logstash/filter-strip-ansi-color.conf',
        priority => 15,
    }

    ## Input specific processing (20)

    logstash::conf { 'filter_syslog':
        source   => 'puppet:///modules/profile/logstash/filter-syslog.conf',
        priority => 20,
    }

    logstash::conf { 'filter_syslog_network':
        source   => 'puppet:///modules/profile/logstash/filter-syslog-network.conf',
        priority => 20,
    }

    logstash::conf { 'filter_udp2log':
        source   => 'puppet:///modules/profile/logstash/filter-udp2log.conf',
        priority => 20,
    }

    logstash::conf { 'filter_gelf':
        source   => 'puppet:///modules/profile/logstash/filter-gelf.conf',
        priority => 20,
    }

    logstash::conf { 'filter_log4j':
        source   => 'puppet:///modules/profile/logstash/filter-log4j.conf',
        priority => 20,
    }

    logstash::conf { 'filter_logback':
        source   => 'puppet:///modules/profile/logstash/filter-logback.conf',
        priority => 20,
    }

    logstash::conf { 'filter_json_lines':
        source   => 'puppet:///modules/profile/logstash/filter-json-lines.conf',
        priority => 20,
    }

    # rsyslog-shipper processing might tweak/adjust some generic syslog fields
    # thus process this filter after all inputs
    logstash::conf { 'filter_rsyslog_shipper':
        source   => 'puppet:///modules/profile/logstash/filter-rsyslog-shipper.conf',
        priority => 25,
    }

    ## Application specific processing (50)

    logstash::conf { 'filter_mediawiki':
        source   => 'puppet:///modules/profile/logstash/filter-mediawiki.conf',
        priority => 50,
    }

    logstash::conf { 'filter_striker':
        source   => 'puppet:///modules/profile/logstash/filter-striker.conf',
        priority => 50,
    }

    logstash::conf { 'filter_ores':
        source   => 'puppet:///modules/profile/logstash/filter-ores.conf',
        priority => 50,
    }

    logstash::conf { 'filter_mjolnir':
        source   => 'puppet:///modules/profile/logstash/filter-mjolnir.conf',
        priority => 50,
    }

    logstash::conf { 'filter_webrequest':
        source   => 'puppet:///modules/profile/logstash/filter-webrequest.conf',
        priority => 50,
    }

    logstash::conf { 'filter_apache2_error':
        source   => 'puppet:///modules/profile/logstash/filter-apache2-error.conf',
        priority => 50,
    }

    logstash::conf { 'filter_rsyslog_multiline':
        source   => 'puppet:///modules/profile/logstash/filter-rsyslog-multiline.conf',
        priority => 50,
    }

    ## Global post-processing (70)

    logstash::conf { 'filter_add_normalized_message':
        source   => 'puppet:///modules/profile/logstash/filter-add-normalized-message.conf',
        priority => 70,
    }

    logstash::conf { 'filter_normalize_log_levels':
        source   => 'puppet:///modules/profile/logstash/filter-normalize-log-levels.conf',
        priority => 70,
    }

    logstash::conf { 'filter_de_dot':
        source   => 'puppet:///modules/profile/logstash/filter-de_dot.conf',
        priority => 70,
    }

    logstash::conf { 'filter_es_index_name':
        source   => 'puppet:///modules/profile/logstash/filter-es-index-name.conf',
        priority => 70,
    }

    ## Outputs (90)
    # Template for Elasticsearch index creation
    file { '/etc/logstash/elasticsearch-template.json':
        ensure => present,
        source => 'puppet:///modules/profile/logstash/elasticsearch-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    # lint:endignore

    logstash::output::elasticsearch { 'logstash':
        host            => '127.0.0.1',
        guard_condition => '"es" in [tags]',
        index           => '%{[@metadata][index_name]}-%{+YYYY.MM.dd}',
        manage_indices  => true,
        priority        => 90,
        template        => '/etc/logstash/elasticsearch-template.json',
        require         => File['/etc/logstash/elasticsearch-template.json'],
    }

    logstash::output::statsd { 'MW_channel_rate':
        host            => $statsd_host,
        guard_condition => '[type] == "mediawiki" and "es" in [tags]',
        namespace       => 'logstash.rate',
        sender          => 'mediawiki',
        increment       => [ '%{channel}.%{level}' ],
    }

    logstash::output::statsd { 'OOM_channel_rate':
        host            => $statsd_host,
        guard_condition => '[type] == "hhvm" and [message] =~ "request has exceeded memory limit"',
        namespace       => 'logstash.rate',
        sender          => 'oom',
        increment       => [ '%{level}' ],
    }

    logstash::output::statsd { 'HHVM_channel_rate':
        host            => $statsd_host,
        guard_condition => '[type] == "hhvm" and [message] !~ "request has exceeded memory limit"',
        namespace       => 'logstash.rate',
        sender          => 'hhvm',
        increment       => [ '%{level}' ],
    }

    logstash::output::statsd { 'Apache2_channel_rate':
        host            => $statsd_host,
        guard_condition => '[type] == "apache2" and "syslog" in [tags]',
        namespace       => 'logstash.rate',
        sender          => 'apache2',
        increment       => [ '%{level}' ],
    }

    # Alerting
    monitoring::check_prometheus { 'logstash-udp-loss-ratio':
        description     => 'Packet loss ratio for UDP',
        dashboard_links => ['https://grafana.wikimedia.org/dashboard/db/logstash'],
        query           => "sum(rate(node_netstat_Udp_InErrors{instance=\"${::hostname}:9100\"}[5m]))/(sum(rate(node_netstat_Udp_InErrors{instance=\"${::hostname}:9100\"}[5m]))+sum(rate(node_netstat_Udp_InDatagrams{instance=\"${::hostname}:9100\"}[5m])))",
        warning         => 0.05,
        critical        => 0.10,
        method          => 'ge',
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
    }

    # Ship logstash server logs to ELK using startmsg_regex pattern to join multi-line events based on datestamp
    # example: [2018-11-30T16:13:48,043]
    rsyslog::input::file { 'logstash-multiline':
        path           => '/var/log/logstash/logstash-plain.log',
        startmsg_regex => '^\\\\[[0-9,-\\\\ \\\\:]+\\\\]',
    }

}
