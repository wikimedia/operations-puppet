# == Class elasticsearch::notifications
# Sets up icinga alerts for an elasticsearch instance.
# Make sure your Nagios/Icinga node has included
# the elasticsearch::nagios::plugin class.
#
class elasticsearch::nagios::check {
    monitor_service { 'elasticsearch':
        check_command => 'check_elasticsearch',
        description   => 'ElasticSearch health check',
    }

    monitor_service { 'elasticsearch shards':
        check_command => 'check_elasticsearch_shards',
        description   => 'ElasticSearch health check for shards',
    }
}
