# == Class elasticsearch::nagios::check
# Sets up icinga alerts for an elasticsearch instance.
# Make sure your Nagios/Icinga node has included
# the elasticsearch::nagios::plugin class.
#
# [*threshold*]
#   The ratio of inactive shards to check (initializing / relocating /
#   unassigned).
#   Default: '>=0.1'
class elasticsearch::nagios::check(
    String $threshold = '>=0.15',
    Array[Wmflib::IpPort] $http_ports = [9200],
) {
    $http_ports.each |$http_port| {
        monitoring::service { "elasticsearch shards ${http_port}":
            check_command => "check_elasticsearch_shards_threshold!${http_port}!${threshold}",
            description   => "ElasticSearch health check for shards on ${http_port}",
        }
    }
}
