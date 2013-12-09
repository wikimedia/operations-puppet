# vim:sw=4 ts=4 sts=4 et:

# = Class: logstash::output::elasticsearch
#
# Configure logstash to output to elasticsearch
#
# == Parameters:
# - $host: Elasticsearch server to contact
# - $flush_size: Maximum number of events to buffer before sending
# - $idle_flush_time: Maxmimum seconds to wait between sends
# - $index: Index to write events to
# - $port: Elasticsearch server port
# - $replication: Type of elasticsearch replication to use ('async', 'sync')
# - $require_tag: Tag to require on events
# - $manage_indices: Install cron jobs to manage elasticsearch indices
# - $priority: Configuration loading priority. Default '10'.
# - $ensure: Whether the config should exist.
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
    $manage_indices  = undef,
    $priority        = 10,
    $ensure          = present,
) {
    require logstash

    @logstash::conf{ 'output-elasticsearch':
        content  => template('logstash/output/elasticsearch.erb'),
        priority => $priority,
        ensure   => $ensure,
    }

    # TODO: add support for manage_template when we upgrade to v1.3.2+

    file { "/usr/local/bin/logstash_delete_index.sh":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///files/logstash/logstash_delete_index.sh',
    }

    file { "/usr/local/bin/logstash_optimize_index.sh":
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///files/logstash/logstash_optimize_index.sh',
    }

    $ensure_cron = $manage_indices ? {
        'true'  => 'present',
        default => 'absent'
    }

    cron { 'logstash_delete_index':
        ensure  => $ensure_cron,
        command => "/usr/local/bin/logstash_delete_index.sh http://${host}:${port}",
        user    => 'root',
        hour    => '2',
        minute  => '0',
        require => File['/usr/local/bin/logstash_delete_index.sh'],
    }

    cron { 'logstash_optimize_index':
        ensure  => $ensure_cron,
        command => "/usr/local/bin/logstash_optimize_index.sh http://${host}:${port}",
        user    => 'root',
        hour    => '1',
        minute  => fqdn_rand(60, 'logstash_optimize_index'),
        require => File['/usr/local/bin/logstash_optimize_index.sh'],
    }

}
