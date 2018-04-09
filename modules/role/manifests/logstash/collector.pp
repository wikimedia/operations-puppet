# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash::collector
#
# Provisions Logstash and an Elasticsearch node to proxy requests to ELK stack
# Elasticsearch cluster.
#
# == Parameters:
# - $statsd_host: Host to send statsd data to.
#
# filtertags: labs-project-deployment-prep
class role::logstash::collector (
    $statsd_host,
) {
    include ::role::logstash::elasticsearch
    include ::logstash
    include ::profile::base::firewall

    nrpe::monitor_service { 'logstash':
        description  => 'logstash process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u logstash -C java -a logstash',
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

    ## Global pre-processing (15)

    # move files into module?
    # lint:ignore:puppet_url_without_modules
    logstash::conf { 'filter_strip_ansi_color':
        source   => 'puppet:///modules/role/logstash/filter-strip-ansi-color.conf',
        priority => 15,
    }

    ## Input specific processing (20)

    logstash::conf { 'filter_syslog':
        source   => 'puppet:///modules/role/logstash/filter-syslog.conf',
        priority => 20,
    }

    logstash::conf { 'filter_udp2log':
        source   => 'puppet:///modules/role/logstash/filter-udp2log.conf',
        priority => 20,
    }

    logstash::conf { 'filter_gelf':
        source   => 'puppet:///modules/role/logstash/filter-gelf.conf',
        priority => 20,
    }

    logstash::conf { 'filter_log4j':
        source   => 'puppet:///modules/role/logstash/filter-log4j.conf',
        priority => 20,
    }

    logstash::conf { 'filter_logback':
        source   => 'puppet:///modules/role/logstash/filter-logback.conf',
        priority => 20,
    }

    logstash::conf { 'filter_json_lines':
        source   => 'puppet:///modules/role/logstash/filter-json-lines.conf',
        priority => 20,
    }
    ## Application specific processing (50)

    logstash::conf { 'filter_mediawiki':
        source   => 'puppet:///modules/role/logstash/filter-mediawiki.conf',
        priority => 50,
    }

    logstash::conf { 'filter_striker':
        source   => 'puppet:///modules/role/logstash/filter-striker.conf',
        priority => 50,
    }

    logstash::conf { 'filter_ores':
        source   => 'puppet:///modules/role/logstash/filter-ores.conf',
        priority => 50,
    }

    logstash::conf { 'filter_webrequest':
        source   => 'puppet:///modules/role/logstash/filter-webrequest.conf',
        priority => 50,
    }

    ## Global post-processing (70)

    logstash::conf { 'filter_add_normalized_message':
        source   => 'puppet:///modules/role/logstash/filter-add-normalized-message.conf',
        priority => 70,
    }

    logstash::conf { 'filter_normalize_log_levels':
        source   => 'puppet:///modules/role/logstash/filter-normalize-log-levels.conf',
        priority => 70,
    }

    logstash::conf { 'filter_de_dot':
        source   => 'puppet:///modules/role/logstash/filter-de_dot.conf',
        priority => 70,
    }

    ## Outputs (90)
    # Template for Elasticsearch index creation
    file { '/etc/logstash/elasticsearch-template.json':
        ensure => present,
        source => 'puppet:///modules/role/logstash/elasticsearch-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    # lint:endignore

    logstash::output::elasticsearch { 'logstash':
        host            => '127.0.0.1',
        guard_condition => '"es" in [tags]',
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
}
