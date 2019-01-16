# monitor the different elasticsearch clusters
class icinga::monitor::elasticsearch {

    $clusters = ['eqiad', 'codfw']
    $instances = [
        {'name' => 'search', 'https_port' => '9243'},
        {'name' => 'search-omega', 'https_port' => '9443'},
        {'name' => 'search-psi', 'https_port' => '9643'},
    ]

    $instances.each |$instance| {
        $clusters.each |$cluster| {
            monitoring::service { "elasticsearch shards - ${cluster}(${instance['name']})":
                host          => "search.svc.${cluster}.wmnet",
                check_command => "check_elasticsearch_shards_threshold_via_https!${instance['https_port']}!>=0.15",
                description   => "ElasticSearch health check for shards - ${cluster}(${instance['name']})",
                critical      => false,
                contact_group => 'admins,team-discovery',
            }

            monitoring::service { "elasticsearch / cirrus frozen writes - ${cluster}(${instance['name']})":
                host          => "search.svc.${cluster}.wmnet",
                check_command => "check_cirrus_frozen_writes_via_https!${instance['https_port']}",
                description   => "ElasticSearch health check for frozen writes - ${cluster}(${instance['name']})",
                critical      => true,
                contact_group => 'admins,team-discovery',
            }

            monitoring::service { "elasticsearch / shard size check - ${cluster}(${instance['name']})":
                host           => "search.svc.${cluster}.wmnet",
                check_command  => "check_elasticsearch_shard_size_via_https!${instance['https_port']}",
                description    => "ElasticSearch shard size check - ${cluster}(${instance['name']})",
                critical       => false,
                check_interval => 1440, # 24h
                retry_interval => 180, # 3h
                retries        => 3,
                contact_group  => 'admins,team-discovery',
            }

            monitoring::service { "elasticsearch / unassigned shard check - ${cluster}(${instance['name']})":
                host           => "search.svc.${cluster}.wmnet",
                check_command  => "check_elasticsearch_unassigned_shards_via_https!${instance['https_port']}",
                description    => "ElasticSearch unassigned shard size check - ${cluster}(${instance['name']})",
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
