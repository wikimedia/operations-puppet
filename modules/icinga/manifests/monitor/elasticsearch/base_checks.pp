# = Class: icinga::monitor::elasticsearch::base_checks
# Icinga check groups. Use lvs checks for lvs enabled clusters
# and nagios checks for host only checks
# == Parameters:
# - $threshold: This is only used when using nagios options for check_group.
# - $scheme: connection scheme, http or https
# - $ports: elasticsearch instance port.
define icinga::monitor::elasticsearch::base_checks(
    String $threshold = '>=0.15',
    Enum['http', 'https'] $scheme = 'http',
    String $host = $::hostname,
    Array[Wmflib::IpPort] $ports = [9200],
) {
    $ports.each |$port| {
        monitoring::service {
            default:
                host          => $host,
                critical      => false,
                contact_group => 'admins,team-discovery',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Search#Administration',
            ;
            "elasticsearch shards ${host}:${port}":
                check_command => "check_elasticsearch_shards_threshold!${scheme}!${port}!${threshold}",
                description   => "ElasticSearch health check for shards on ${port}",
            ;
            "elasticsearch / unassigned shard check - ${host}:${port}":
                check_command  => "check_elasticsearch_unassigned_shards!${scheme}!${port}",
                description    => "ElasticSearch unassigned shard check - ${port})",
                check_interval => 720, # 12h
                retry_interval => 120, # 2h
                retries        => 1,
            ;
            "elasticsearch / shard size check - ${host}:${port})":
                check_command  => "check_elasticsearch_shard_size!${scheme}!${port}",
                description    => "ElasticSearch shard size check - ${port}",
                check_interval => 1440, # 24h
                retry_interval => 180, # 3h
                notes_url      => 'https://wikitech.wikimedia.org/wiki/Search#If_it_has_been_indexed',
            ;
        }
    }
}