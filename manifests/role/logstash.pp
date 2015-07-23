# vim:sw=4 ts=4 sts=4 et:
@monitoring::group { 'logstash_eqiad': description => 'eqiad logstash' }

# == Class: role::logstash
#
# Provisions Logstash and ElasticSearch.
#
class role::logstash {
    include standard
    include ::elasticsearch::ganglia
    include ::elasticsearch::nagios::check
    include ::logstash

    package { 'elasticsearch/plugins':
        provider => 'trebuchet',
    }

    class { '::elasticsearch':
        require => Package['elasticsearch/plugins'],
    }

    logstash::input::udp2log { 'mediawiki':
        port => 8324,
    }

    logstash::input::syslog { 'syslog':
        port => 10514,
    }

    logstash::input::gelf { 'gelf':
        port => 12201,
    }

    logstash::input::udp { 'logback':
        port  => 11514,
        codec => 'json',
    }

    ## Global pre-processing (10)

    logstash::conf { 'filter_strip_ansi_color':
        source   => 'puppet:///files/logstash/filter-strip-ansi-color.conf',
        priority => 10,
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

    class { '::logstash::output::elasticsearch':
        host           => '127.0.0.1',
        replication    => 'async',
        require_tag    => 'es',
        manage_indices => true,
        priority       => 90,
    }

}

# == Class: role::logstash::elasticsearch
#
# Provisions Elasticsearch backend node for a Logstash cluster.
#
class role::logstash::elasticsearch {
    include standard
    include ::elasticsearch::ganglia
    include ::elasticsearch::nagios::check

    package { 'elasticsearch/plugins':
        provider => 'trebuchet',
    }

    class { '::elasticsearch':
        require => Package['elasticsearch/plugins'],
    }
}

# == Class: role::logstash::ircbot
#
# Sets up an IRC Bot to log messages from certain IRC channels
class role::logstash::ircbot {
    require ::role::logstash

    $irc_name = $::logstash_irc_name ? {
        undef => "logstash-${::labsproject}",
        default => $::logstash_irc_name,
    }

    logstash::input::irc { 'freenode':
        user     => $irc_name,
        nick     => $irc_name,
        channels => ['#wikimedia-labs', '#wikimedia-releng', '#wikimedia-operations'],
    }

    logstash::conf { 'filter_irc_banglog':
        source   => 'puppet:///files/logstash/filter-irc-banglog.conf',
        priority => 50,
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

    # Variables for the templates
    $host            = $::realm ? {
        'production' => '10.2.2.30', # search.svc.eqiad.wmnet
        'labs'       => 'deployment-elastic05', # Pick one at random
    }
    $port            = 9200

    $uri = "http://${host}:${port}"

    # Add the index to ES
    file { '/etc/logstash/apifeatureusage-elasticsearch-template.json':
        ensure => present,
        source => 'puppet:///files/logstash/apifeatureusage-elasticsearch-template.json',
    }

    exec { 'Create apifeatureusage index template':
        command => template('logstash/create-apifeatureusage-index.erb'),
        unless  => template('logstash/check-apifeatureusage-index.erb'),
        require => [
            Service['elasticsearch'],
            File['/etc/logstash/apifeatureusage-elasticsearch-template.json'],
        ]
    }

    # Add configuration to logstash
    # Needs to come after 'filter_mediawiki' (priority 50)
    logstash::conf { 'filter_apifeatureusage':
        source   => 'puppet:///files/logstash/filter-apifeatureusage.conf',
        priority => 55,
    }

    # Output destined for separate Elasticsearch cluster from Logstash cluster
    logstash::conf{ 'output-apifeatureusage':
        content  => template('logstash/apifeatureusage.erb'),
        priority => 95,
    }

    # Cron jobs to delete and optimize indexes
    cron { 'apifeatureusage_delete_index':
        command => "/usr/local/bin/logstash_delete_index.sh ${uri} \"apifeatureusage-$(date -d '-31days' +\\%Y.\\%m.\\%d)\"",
        user    => 'root',
        hour    => 0,
        minute  => 42,
        require => File['/usr/local/bin/logstash_delete_index.sh'],
    }

    cron { 'apifeatureusage_optimize_index':
        command => "/usr/local/bin/logstash_optimize_index.sh ${uri} \"apifeatureusage-$(date -d '-1day' +\\%Y.\\%m.\\%d)\"",
        user    => 'root',
        hour    => 1,
        # Stagger execution on each node of cluster to avoid running in
        # parallel.
        minute  => 5 * fqdn_rand(12, 'apifeatureusage_optimize_index'),
        require => File['/usr/local/bin/logstash_optimize_index.sh'],
    }
}
