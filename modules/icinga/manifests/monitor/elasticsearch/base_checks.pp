# = Define: icinga::monitor::elasticsearch::base_checks
define icinga::monitor::elasticsearch::base_checks(
    String $threshold = '>=0.15',
    Enum['http', 'https'] $scheme = 'http',
    String $host = $::hostname,
    Array[Wmflib::IpPort] $ports = [9200],
    Integer $shard_size_warning = 50,
    Integer $shard_size_critical = 60,
    Boolean $use_nrpe = false,
) {
    $ports.each |$port| {
        # yes yes! a lot of duplication here which could be improved.
        # they will remain here until we find a better way
        # also always update both checks!
        if !$use_nrpe {
            monitoring::service {
                default:
                    host          => $host,
                    critical      => false,
                    contact_group => 'admins,team-discovery',
                    notes_url     => 'https://wikitech.wikimedia.org/wiki/Search#Administration',
                ;
                "elasticsearch_shards_${host}:${port}":
                    check_command => "check_elasticsearch_shards_threshold!${scheme}!${port}!${threshold}",
                    description   => "ElasticSearch health check for shards on ${port}",
                ;
                "elasticsearch_unassigned_shard_check_${host}:${port}":
                    check_command  => "check_elasticsearch_unassigned_shards!${scheme}!${port}",
                    description    => "ElasticSearch unassigned shard check - ${port}",
                    check_interval => 720, # 12h
                    retry_interval => 120, # 2h
                    retries        => 1,
                ;
                "elasticsearch_shard_size_check_${host}:${port}":
                    check_command  => "check_elasticsearch_shard_size!${scheme}!${port}!${shard_size_warning}!${shard_size_critical}",
                    description    => "ElasticSearch shard size check - ${port}",
                    check_interval => 1440, # 24h
                    retry_interval => 180, # 3h
                    notes_url      => 'https://wikitech.wikimedia.org/wiki/Search#If_it_has_been_indexed',
                ;
            }
        } else {
            require ::icinga::elasticsearch::base_plugin

            nrpe::monitor_service {
                default:
                    critical      => false,
                    contact_group => 'admins,team-discovery',
                    notes_url     => 'https://wikitech.wikimedia.org/wiki/Search#Administration',
                ;
                "elasticsearch_shards_${port}":
                    nrpe_command => "/usr/lib/nagios/plugins/check_elasticsearch.py --ignore-status --url http://localhost:${port} --shards-inactive '${threshold}'",
                    description  => "ElasticSearch health check for shards on ${port}",
                ;
                "elasticsearch_unassigned_shard_check_${port}":
                    nrpe_command   => "/usr/lib/nagios/plugins/check_elasticsearch_unassigned_shards.py --url http://localhost:${port}",
                    description    => "ElasticSearch unassigned shard check - ${port}",
                    check_interval => 720, # 12h
                    retry_interval => 120, # 2h
                    retries        => 1,
                ;
                "elasticsearch_shard_size_check_${port}":
                    nrpe_command   => "/usr/lib/nagios/plugins/check_elasticsearch_shard_size.py --url http://localhost:${port} --shard-size-warning ${shard_size_warning} --shard-size-critical ${shard_size_critical}",
                    description    => "ElasticSearch shard size check - ${port}",
                    check_interval => 1440, # 24h
                    retry_interval => 180, # 3h
                    notes_url      => 'https://wikitech.wikimedia.org/wiki/Search#If_it_has_been_indexed',
                ;
            }
        }
    }
}