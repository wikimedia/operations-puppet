# monitor the different elasticsearch clusters
class icinga::monitor::elasticsearch {

    $threshold = '>=0.15'
    $http_port = 9200

    monitoring::service { 'elasticsearch shards - eqiad':
        host          => 'search.svc.eqiad.wmnet',
        check_command => "check_elasticsearch_shards_threshold!${http_port}!${threshold}",
        description   => 'ElasticSearch health check for shards',
        critical      => false,
        contact_group => 'admins,team-discovery',
    }

    monitoring::service { 'elasticsearch shards - codfw':
        host          => 'search.svc.codfw.wmnet',
        check_command => "check_elasticsearch_shards_threshold!${http_port}!${threshold}",
        description   => 'ElasticSearch health check for shards',
        critical      => false,
        contact_group => 'admins,team-discovery',
    }

    monitoring::service { 'elasticsearch / cirrus frozen writes - eqiad':
        host          => 'search.svc.eqiad.wmnet',
        check_command => "check_cirrus_frozen_writes!${http_port}",
        description   => 'ElasticSearch health check for frozen writes',
        critical      => true,
        contact_group => 'admins,team-discovery',
    }

    monitoring::service { 'elasticsearch / cirrus frozen writes - codfw':
        host          => 'search.svc.codfw.wmnet',
        check_command => "check_cirrus_frozen_writes!${http_port}",
        description   => 'ElasticSearch health check for frozen writes',
        critical      => true,
        contact_group => 'admins,team-discovery',
    }

    # this check is throttled to reduce the noise from segment merges.
    monitoring::service { 'elasticsearch / shard size check - eqiad':
        host           => 'search.svc.eqiad.wmnet',
        check_command  => "check_elasticsearch_shard_size!${http_port}",
        description    => 'ElasticSearch shard size check',
        critical       => false,
        check_interval => 1440, # 24h
        retry_interval => 180, # 3h
        retries        => 3,
        contact_group  => 'admins,team-discovery',
    }

    monitoring::service { 'elasticsearch / shard size check - codfw':
        host           => 'search.svc.codfw.wmnet',
        check_command  => "check_elasticsearch_shard_size!${http_port}",
        description    => 'ElasticSearch shard size check',
        critical       => false,
        check_interval => 1440, # 24h
        retry_interval => 180, # 3h
        retries        => 3,
        contact_group  => 'admins,team-discovery',
    }

    monitoring::service { 'elasticsearch / unassigned shard check - eqiad':
        host           => 'search.svc.eqiad.wmnet',
        check_command  => "check_elasticsearch_unassigned_shards!${http_port}",
        description    => 'ElasticSearch unassigned shard size check',
        critical       => false,
        check_interval => 720, # 12h
        retry_interval => 120, # 2h
        retries        => 1,
        notes_url      => 'https://grafana.wikimedia.org/d/000000455/elasticsearch-percentiles?panelId=64&fullscreen&orgId=1&var-cluster=eqiad',
        contact_group  => 'admins,team-discovery',
    }

    monitoring::service { 'elasticsearch / unassigned shard size check - codfw':
        host           => 'search.svc.codfw.wmnet',
        check_command  => "check_elasticsearch_unassigned_shards!${http_port}",
        description    => 'ElasticSearch unassigned shard size check',
        critical       => false,
        check_interval => 720, # 12h
        retry_interval => 120, # 2h
        retries        => 1,
        notes_url      => 'https://grafana.wikimedia.org/d/000000455/elasticsearch-percentiles?panelId=64&fullscreen&orgId=1&var-cluster=codfw',
        contact_group  => 'admins,team-discovery',
    }


}
