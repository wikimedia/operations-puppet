# vim:sw=4 ts=4 sts=4 et:

# = Class: logstash::output::elasticsearch
#
# Configure logstash to output to elasticsearch
#
# == Parameters:
# - $host: Elasticsearch server. Default '127.0.0.1'.
# - $flush_size: Maximum number of events to buffer before sending.
#       Default 100.
# - $idle_flush_time: Maxmimum seconds to wait between sends. Default 1.
# - $index: Index to write events to. Default 'logstash-%{+YYYY.MM.dd}'.
# - $port: Elasticsearch server port. Default 9200.
# - $replication: Type of elasticsearch replication to use ('async', 'sync').
#       Default 'sync'.
# - $require_tag: Tag to require on events. Default undef.
# - $manage_indices: Whether cron jobs should be installed to manage
#       elasticsearch indices. Default false.
# - $priority: Configuration loading priority. Default 10.
# - $ensure: Whether the config should exist. Default present.
#
# == Sample usage:
#
#   class { 'logstash::output::elasticsearch':
#       host           => '127.0.0.1',
#       replication    => 'async',
#       require_tag    => 'es',
#       manage_indices => 'true',
#   }
#
class logstash::output::elasticsearch(
    $host            = '127.0.0.1',
    $flush_size      = 100,
    $idle_flush_time = 1,
    $index           = 'logstash-%{+YYYY.MM.dd}',
    $port            = 9200,
    $replication     = 'sync',
    $require_tag     = undef,
    $manage_indices  = false,
    $priority        = 10,
    $ensure          = present,
) {
    $uri = "http://${host}:${port}"

    logstash::conf{ 'output-elasticsearch':
        ensure   => $ensure,
        content  => template('logstash/output/elasticsearch.erb'),
        priority => $priority,
    }

    # TODO: add support for manage_template when we upgrade to v1.3.2+

    file { '/usr/local/bin/logstash_delete_index.sh':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/logstash/logstash_delete_index.sh',
    }

    file { '/usr/local/bin/logstash_optimize_index.sh':
        ensure => $ensure,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/logstash/logstash_optimize_index.sh',
    }

    $ensure_cron = $manage_indices ? {
        true    => 'present',
        default => 'absent'
    }

    cron { 'logstash_delete_index':
        ensure  => $ensure_cron,
        command => "/usr/local/bin/logstash_delete_index.sh ${uri}",
        user    => 'root',
        hour    => 0,
        minute  => 42,
        require => File['/usr/local/bin/logstash_delete_index.sh'],
    }

    cron { 'logstash_optimize_index':
        ensure  => $ensure_cron,
        command => "/usr/local/bin/logstash_optimize_index.sh ${uri}",
        user    => 'root',
        hour    => 1,
        # Stagger execution on each node of cluster to avoid running in
        # parallel.
        minute  => 5 * fqdn_rand(12, 'logstash_optimize_index'),
        require => File['/usr/local/bin/logstash_optimize_index.sh'],
    }

}
