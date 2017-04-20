# == Class elasticsearch::nagios::check
# Sets up icinga alerts for an elasticsearch instance.
# Make sure your Nagios/Icinga node has included
# the elasticsearch::nagios::plugin class.
#
# [*threshold*]
#   The percentage of inactive shards to check (initializing / relocating /
#   unassigned).
#   Default: 0.1
class elasticsearch::nagios::check(
    $threshold = '0.1',
) {
    monitoring::service { 'elasticsearch shards':
        check_command => "check_elasticsearch_shards_threshold!${threshold}",
        description   => 'ElasticSearch health check for shards',
    }
}
