# monitor the different elasticsearch clusters
class icinga::monitor::elasticsearch {

    monitoring::service { 'elasticsearch shards - eqiad':
        host          => 'search.svc.eqiad.wmnet',
        check_command => 'check_elasticsearch_shards',
        description   => 'ElasticSearch health check for shards',
        critical      => true,
        contact_group => 'admins,team-discovery',
    }

    monitoring::service { 'elasticsearch shards - codfw':
        host          => 'search.svc.codfw.wmnet',
        check_command => 'check_elasticsearch_shards',
        description   => 'ElasticSearch health check for shards',
        critical      => true,
        contact_group => 'admins,team-discovery',
    }

}
