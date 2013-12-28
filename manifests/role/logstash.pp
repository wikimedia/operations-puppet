@monitor_group { 'logstash_eqiad': description => 'eqiad logstash' }

# == Class: role::logstash
#
# Provisions LogStash, Redis, and ElasticSearch.
#
class role::logstash {
    include ::elasticsearch::ganglia
    include ::elasticsearch::nagios::check

    deployment::target { 'elasticsearchplugins': }

    class { '::elasticsearch':
        multicast_group      => '224.2.2.5',
        master_eligible      => true,
        minimum_master_nodes => 2,
        cluster_name         => "production-logstash-${::site}",
        heap_memory          => '5G',
        plugins_dir          => '/srv/deployment/elasticsearch/plugins',
    }

    include ::passwords::logstash

    class { '::redis':
        maxmemory         => '1Gb',
        dir               => '/var/run/redis',
        persist           => undef,
        redis_replication => undef,
        password          => $passwords::logstash::redis,
    }

    include ::redis::ganglia

    class { '::kibana':
        hostname     => 'kibana.wikimedia.org',
        ldap_authurl => 'ldaps://virt0.wikimedia.org virt1000.wikimedia.org/ou=people,dc=wikimedia,dc=org?cn',
        ldap_binddn  => 'cn=proxyagent,ou=profile,dc=wikimedia,dc=org',
        ldap_group   => 'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        auth_realm   => 'WMF Labs (use wiki login name not shell)',
    }
}
