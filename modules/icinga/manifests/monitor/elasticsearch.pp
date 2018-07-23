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


}
