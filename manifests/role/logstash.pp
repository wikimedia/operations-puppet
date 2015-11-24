# vim:sw=4 ts=4 sts=4 et:
# == Class: role::logstash
#
# Provisions Logstash and ElasticSearch.
#
# == Parameters:
# - $statsd_host: Host to send statsd data to.
#
class role::logstash (
    $statsd_host,
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

    ## Outputs (90)
    # Template for Elasticsearch index creation
    file { '/etc/logstash/elasticsearch-template.json':
        ensure => present,
        source => 'puppet:///files/logstash/elasticsearch-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }

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

    logstash::conf { 'filter_puppet':
        source   => 'puppet:///files/logstash/filter-puppet.conf',
        priority => 50,
    }
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

# == Class: role::logstash::stashbot
#
# Configure logstash to record IRC channel messages
#
# == Parameters:
# [*irc_user*]
#   IRC username
#
# [*irc_pass*]
#   IRC password
#
# [*irc_nick*]
#   IRC nick
#
# [*irc_real*]
#   IRC real name
#
# [*channels*]
#   List of channels to join and log
#
class role::logstash::stashbot (
    $irc_user = 'stashbot',
    $irc_pass = undef,
    $irc_nick = 'stashbot',
    $irc_real = 'Wikimedia Tool Labs IRC bot',
    $channels = [],
) {
    include ::role::logstash::elasticsearch
    include ::logstash

    logstash::input::irc { 'freenode':
        user     => $irc_user,
        password => $irc_pass,
        nick     => $irc_nick,
        real     => $irc_real,
        channels => $channels,
    }

    logstash::conf { 'filter_strip_ansi_color':
        source   => 'puppet:///files/logstash/filter-strip-ansi-color.conf',
        priority => 15,
    }

    # ferm::service not needed as irc connection is made outbound

    logstash::conf { 'filter_stashbot':
        source   => 'puppet:///files/logstash/filter-stashbot.conf',
        priority => 20,
    }

    logstash::conf { 'filter_stashbot_sal':
        source   => 'puppet:///files/logstash/filter-stashbot-sal.conf',
        priority => 50,
    }

    logstash::conf { 'filter_stashbot_bash':
        source   => 'puppet:///files/logstash/filter-stashbot-bash.conf',
        priority => 50,
    }

    file { '/etc/logstash/stashbot-template.json':
        ensure => present,
        source => 'puppet:///files/logstash/stashbot-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    logstash::output::elasticsearch { 'logstash':
        host            => '127.0.0.1',
        index           => 'logstash-%{+YYYY.MM}',
        guard_condition => '"es" in [tags]',
        priority        => 90,
        template        => '/etc/logstash/stashbot-template.json',
        require         => File['/etc/logstash/stashbot-template.json'],
    }

    # Special indexing for SAL messages
    file { '/etc/logstash/stashbot-sal-template.json':
        ensure => present,
        source => 'puppet:///files/logstash/stashbot-sal-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    logstash::output::elasticsearch { 'sal':
        host            => $host,
        index           => 'sal',
        guard_condition => '[type] == "sal"',
        priority        => 95,
        template        => '/etc/logstash/stashbot-sal-template.json',
        require         => File['/etc/logstash/stashbot-sal-template.json'],
    }

    # Special indexing for bash messages
    file { '/etc/logstash/stashbot-bash-template.json':
        ensure => present,
        source => 'puppet:///files/logstash/stashbot-bash-template.json',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
    }
    logstash::output::elasticsearch { 'bash':
        host            => $host,
        index           => 'bash',
        guard_condition => '[type] == "bash"',
        priority        => 95,
        template        => '/etc/logstash/stashbot-bash-template.json',
        require         => File['/etc/logstash/stashbot-bash-template.json'],
    }
}

# == Class: role::logstash::eventlogging
#
# Configure Logstash to consume validation logs from EventLogging.
#
class role::logstash::eventlogging {
    include ::role::logstash
    include ::role::analytics::kafka::config

    $topic = 'eventlogging_EventError'

    logstash::input::kafka { $topic:
        tags       => [$topic, 'kafka'],
        type       => 'eventlogging',
        zk_connect => $role::analytics::kafka::config::zookeeper_url,
    }

    logstash::conf { 'filter_eventlogging':
        source   => 'puppet:///files/logstash/filter-eventlogging.conf',
        priority => 50,
    }
}
