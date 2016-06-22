# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash
#
# Provisions Logstash and ElasticSearch.
#
# == Parameters:
# - $statsd_host: Host to send statsd data to.
# - $logstash_alt_host: Additional host to send logstash elasticsearch
#    output to. Used for testing elasticsearch 2.3 deployment.
# - $replicas: Number of times to replicate logs across the cluster
#
class role::logstash (
    $statsd_host,
    $logstash_alt_host = undef,
    $replicas = 2,
) {
    include ::role::logstash::elasticsearch
    include ::logstash

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
        srange  => '$ALL_NETWORKS',
    }

    logstash::input::syslog { 'syslog':
        port => 10514,
    }

    ferm::service { 'logstash_syslog':
        proto   => 'udp',
        port    => '10514',
        notrack => true,
        srange  => '$ALL_NETWORKS',
    }

    ferm::service { 'grafana_dashboard_definition_storage':
        proto  => 'tcp',
        port   => '9200',
        srange => '@resolve(krypton.eqiad.wmnet)',
    }

    logstash::input::gelf { 'gelf':
        port => 12201,
    }

    ferm::service { 'logstash_gelf':
        proto   => 'udp',
        port    => '12201',
        notrack => true,
        srange  => '$ALL_NETWORKS',
    }

    logstash::input::udp { 'logback':
        port  => 11514,
        codec => 'json',
    }

    ferm::service { 'logstash_udp':
        proto   => 'udp',
        port    => '11514',
        notrack => true,
        srange  => '$ALL_NETWORKS',
    }

    ## Global pre-processing (15)

    # move files into module?
    # lint:ignore:puppet_url_without_modules
    logstash::conf { 'filter_strip_ansi_color':
        source   => 'puppet:///files/logstash/filter-strip-ansi-color.conf',
        priority => 15,
    }

    ## Input specific processing (20)

    logstash::conf { 'filter_syslog':
        source   => 'puppet:///files/logstash/filter-syslog.conf',
        priority => 20,
    }

    logstash::conf { 'filter_udp2log':
        source   => 'puppet:///files/logstash/filter-udp2log.conf',
        priority => 20,
    }

    logstash::conf { 'filter_gelf':
        source   => 'puppet:///files/logstash/filter-gelf.conf',
        priority => 20,
    }

    logstash::conf { 'filter_logback':
        source   => 'puppet:///files/logstash/filter-logback.conf',
        priority => 20,
    }

    ## Application specific processing (50)

    logstash::conf { 'filter_mediawiki':
        source   => 'puppet:///files/logstash/filter-mediawiki.conf',
        priority => 50,
    }

    ## Global post-processing (70)

    logstash::conf { 'filter_add_normalized_message':
        source   => 'puppet:///files/logstash/filter-add-normalized-message.conf',
        priority => 70,
    }

    logstash::conf { 'filter_normalize_log_levels':
        source   => 'puppet:///files/logstash/filter-normalize-log-levels.conf',
        priority => 70,
    }

    logstash::conf { 'filter_normalize_fields':
        source   => 'puppet:///files/logstash/filter-normalize_fields.conf',
        priority => 70,
    }

    logstash::conf { 'filter_de_dot':
        source   => 'puppet:///files/logstash/filter-do_dot.conf',
        priority => 70,
    }

    ## Outputs (90)
    # Template for Elasticsearch index creation
    file { '/etc/logstash/elasticsearch-template.json':
        ensure  => present,
        content => template('logstash/elasticsearch-template.json.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
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

    if ($logstash_alt_host) {
        logstash::output::elasticsearch { 'logstash-alt':
            template_name   => 'logstash',
            index_prefix    => 'logstash',
            host            => $logstash_alt_host,
            guard_condition => '"es" in [tags]',
            manage_indices  => true,
            priority        => 90,
            template        => '/etc/logstash/elasticsearch-template.json',
            require         => File['/etc/logstash/elasticsearch-template.json'],
        }
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

# == Class: role::logstash::elasticsearch
#
# Provisions Elasticsearch backend node for a Logstash cluster.
#
class role::logstash::elasticsearch {
    include standard
    include ::elasticsearch::nagios::check

    if $::standard::has_ganglia {
        include ::elasticsearch::ganglia
    }

    package { 'elasticsearch/plugins':
        provider => 'trebuchet',
    }

    class { '::elasticsearch':
        require => Package['elasticsearch/plugins'],
    }

    $logstash_nodes = hiera('logstash::cluster_hosts')
    $logstash_nodes_ferm = join($logstash_nodes, ' ')

    ferm::service { 'logstash_elastic_internode':
        proto   => 'tcp',
        port    => 9300,
        notrack => true,
        srange  => "@resolve((${logstash_nodes_ferm}))",
    }
}

# == Class: role::logstash::puppetreports
#
# Set up a TCP listener to listen for puppet failure reports.
class role::logstash::puppetreports {
    require ::role::logstash

    if $::realm != 'labs' {
        # Constrain to only labs, security issues in prod have not been worked out yet
        fail('role::logstash::puppetreports may only be deployed to Labs.')
    }

    logstash::input::tcp { 'tcp_json':
        port  => 5229,
        codec => 'json_lines',
    }

    ferm::service { 'logstash_tcp_json':
        proto  => 'tcp',
        port   => '5229',
        srange => '$ALL_NETWORKS',
    }

    # lint:ignore:puppet_url_without_modules
    logstash::conf { 'filter_puppet':
        source   => 'puppet:///files/logstash/filter-puppet.conf',
        priority => 50,
    }
    # lint:endignore
}


# == Class: role::logstash::apifeatureusage
#
# Builds on role::logstash to insert sanitized data for
# Extension:ApiFeatureUsage into Elasticsearch.
#
class role::logstash::apifeatureusage {
    include ::role::logstash

    # FIXME: make this a param and use hiera to vary by realm
    $host            = $::realm ? {
        'production' => '10.2.2.30', # search.svc.eqiad.wmnet
        'labs'       => 'deployment-elastic05', # Pick one at random
    }

    # Template for Elasticsearch index creation
    # lint:ignore:puppet_url_without_modules
    file { '/etc/logstash/apifeatureusage-template.json':
        ensure => present,
        source => 'puppet:///files/logstash/apifeatureusage-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

    # Add configuration to logstash
    # Needs to come after 'filter_mediawiki' (priority 50)
    logstash::conf { 'filter_apifeatureusage':
        source   => 'puppet:///files/logstash/filter-apifeatureusage.conf',
        priority => 55,
    }
    # lint:endignore

    # Output destined for separate Elasticsearch cluster from Logstash cluster
    logstash::output::elasticsearch { 'apifeatureusage':
        host            => $host,
        guard_condition => '[type] == "api-feature-usage-sanitized"',
        manage_indices  => true,
        priority        => 95,
        template        => '/etc/logstash/apifeatureusage-template.json',
        require         => File['/etc/logstash/apifeatureusage-template.json'],
    }
}

# == Class: role::logstash::eventlogging
#
# Configure Logstash to consume validation logs from EventLogging.
#
class role::logstash::eventlogging {
    include ::role::logstash

    $topic = 'eventlogging_EventError'
    $kafka_config = kafka_config('analytics')

    logstash::input::kafka { $topic:
        tags       => [$topic, 'kafka'],
        type       => 'eventlogging',
        zk_connect => $kafka_config['zookeeper']['url'],
    }
    # lint:ignore:puppet_url_without_modules
    logstash::conf { 'filter_eventlogging':
        source   => 'puppet:///files/logstash/filter-eventlogging.conf',
        priority => 50,
    }
    # lint:endignore
}
