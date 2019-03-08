# monitor the different elasticsearch clusters
class icinga::monitor::elasticsearch {

    $clusters = ['eqiad', 'codfw']
    $instances = [
        {'name' => 'search', 'port' => '9243'},
        {'name' => 'search-omega', 'port' => '9443'},
        {'name' => 'search-psi', 'port' => '9643'},
    ]
    $scheme = 'https'

    $instances.each |$instance| {
        $clusters.each |$cluster| {
            monitoring::service { "elasticsearch shards - ${cluster}(${instance['name']})":
                host          => "search.svc.${cluster}.wmnet",
                check_command => "check_elasticsearch_shards_threshold!${scheme}!${instance['port']}!>=0.15",
                description   => "ElasticSearch health check for shards - ${cluster}(${instance['name']})",
                critical      => false,
                contact_group => 'admins,team-discovery',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Search#Administration',
            }

            monitoring::service { "elasticsearch / cirrus frozen writes - ${cluster}(${instance['name']})":
                host          => "search.svc.${cluster}.wmnet",
                check_command => "check_cirrus_frozen_writes!${scheme}!${instance['port']}",
                description   => "ElasticSearch health check for frozen writes - ${cluster}(${instance['name']})",
                critical      => true,
                contact_group => 'admins,team-discovery',
                notes_url     => 'https://wikitech.wikimedia.org/wiki/Search#Pausing_Indexing',
            }

            monitoring::service { "elasticsearch / shard size check - ${cluster}(${instance['name']})":
                host           => "search.svc.${cluster}.wmnet",
                check_command  => "check_elasticsearch_shard_size!${scheme}!${instance['port']}",
                description    => "ElasticSearch shard size check - ${cluster}(${instance['name']})",
                critical       => false,
                check_interval => 1440, # 24h
                retry_interval => 180, # 3h
                retries        => 3,
                contact_group  => 'admins,team-discovery',
                notes_url      => 'https://wikitech.wikimedia.org/wiki/Search#If_it_has_been_indexed',
            }

            monitoring::service { "elasticsearch / unassigned shard check - ${cluster}(${instance['name']})":
                host           => "search.svc.${cluster}.wmnet",
                check_command  => "check_elasticsearch_unassigned_shards!${scheme}!${instance['port']}",
                description    => "ElasticSearch unassigned shard check - ${cluster}(${instance['name']})",
                critical       => false,
                check_interval => 720, # 12h
                retry_interval => 120, # 2h
                retries        => 1,
                notes_url      => "https://grafana.wikimedia.org/d/000000455/elasticsearch-percentiles?panelId=64&fullscreen&orgId=1&var-cluster=${cluster}&var-exported_cluster=production-${instance['name']}-${cluster}",
                contact_group  => 'admins,team-discovery',
            }
        }
    }

}
