# Jenkins console logs in ElasticSearch with Kibana
#
# http://ci-log.wmflabs.org/
#
class role::ci::buildlog {

    system::role { 'role::ci::buildlog':
        description => 'CI build log (Kibana + ElasticSearch)'
    }

    require role::labs::lvm::srv

    class { 'role::kibana':
        vhost       => 'ci-log.wmflabs.org',
        serveradmin => 'releng@wikimedia.org',
        auth_type   => 'none',
    }

    class { '::elasticsearch':
        auto_create_index    => '+*',
        cluster_name         => 'ci-log',
        data_dir             => '/srv/elasticsearch',
        expected_nodes       => 1,
        graylog_hosts        => undef,
        heap_memory          => '5G',
        minimum_master_nodes => 1,
        recover_after_nodes  => 1,
        recover_after_time   => '1m',
        cluster_hosts        => ['buildlog.integration.eqiad.wmflabs'],
        unicast_hosts        => ['buildlog.integration.eqiad.wmflabs'],
    }

}
