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
# - $priority: Configuration loading priority. Default '10'.
# - $ensure: Whether the config should exist.
#
# == Sample usage:
#
#   class { 'logstash::output::elasticsearch':
#       host        => '127.0.0.1',
#       replication => 'async',
#       require_tag => 'es',
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
    $priority        = '10',
    $ensure          = present,
) {
    require logstash

    @logstash::conf{ 'output-elasticsearch':
        content  => template('logstash/output/elasticsearch.erb'),
        priority => $priority,
        ensure   => $ensure,
    }

    # TODO: add support for manage_template when we upgrade to v1.3.2+
}
# vim:sw=4 ts=4 sts=4 et:
