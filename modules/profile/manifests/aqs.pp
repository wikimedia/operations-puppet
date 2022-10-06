# SPDX-License-Identifier: Apache-2.0
# == Class profile::aqs
# Analytics Query Service Restbase Service configuration
#
class profile::aqs (
        Boolean $monitoring_enabled                    = lookup('profile::aqs::monitoring_enabled', { 'default_value' => false }),
        Optional[Hash[String, Any]] $druid_properties  = lookup('profile::aqs::druid_properties', { 'default_value' => undef }),
        Optional[Hash[String, Any]] $druid_datasources = lookup('profile::aqs::druid_datasources', { 'default_value' => undef }),
        String $druid_uri_pattern                      = lookup('profile::aqs::druid_uri_pattern'),
        String $cassandra_user                         = lookup('profile::aqs::cassandra_user'),
        String $cassandra_password                     = lookup('profile::aqs::cassandra_password'),
        Array[Stdlib::Host] $cassandra_seeds           = lookup('profile::aqs::seeds'),
        Stdlib::Port $rsyslog_port                     = lookup('rsyslog_port', { 'default_value' => 10514 }),
        String $cassandra_default_consistency          = lookup('profile::aqs::cassandra_default_consistency'),
        String $cassandra_local_dc                     = lookup('profile::aqs::cassandra_local_dc'),
        Optional[Stdlib::Host] $statsd_host            = lookup('profile::aqs::statsd_host', { 'default_value' => undef }),
        Boolean $use_nodejs10                          = lookup('profile::aqs::use_nodejs10', { 'default_value' => false }),
        Boolean $git_deploy                            = lookup('profile::aqs::git_deploy', { 'default_value' => false }),
){

    class { '::aqs':
        cassandra_user                => $cassandra_user,
        cassandra_password            => $cassandra_password,
        druid_datasources             => $druid_datasources,
        druid_properties              => $druid_properties,
        druid_uri_pattern             => $druid_uri_pattern,
        seeds                         => $cassandra_seeds,
        cassandra_default_consistency => $cassandra_default_consistency,
        cassandra_local_dc            => $cassandra_local_dc,
        statsd_host                   => $statsd_host,
        rsyslog_port                  => $rsyslog_port,
        use_nodejs10                  => $use_nodejs10,
        git_deploy                    => $git_deploy,
    }

    ferm::service {'aqs_web':
        proto => 'tcp',
        port  => $::aqs::port,
    }

    if $monitoring_enabled {
        monitoring::service { 'aqs_http_root':
            description   => 'AQS root url',
            check_command => "check_http_port_url!${::aqs::port}!/",
            contact_group => 'admins,team-services,analytics',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/AQS#Monitoring',
        }
        #TODO: add monitoring once we figure out what metrics we want
        #monitoring::graphite_threshold { 'restbase_analytics_<<some-metric-name>>':
            #description   => 'Analytics RESTBase req/s returning 5xx http://grafana.wikimedia.org/d/000000068/restbase',
            #metric        => '<<the metric and any transformations>>',
            #from          => '10min',
            #warning       => <<warning threshold>>, # <<explain>>
            #critical      => <<critical threshold>>, # <<explain>>
            #percentage    => 20,
            #contact_group => 'aqs-admins',
            #notes_link     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/AQS#Monitoring',
        #}
    }

    # T249755
    # Set up temporary rsync modules and a firewall rule
    # in support of the cassndra 3 migration
    # These should be removed once the migration is complete
    if $::fqdn =~ /aqs101[0-5].eqiad.wmnet/ {

        $aqs_hosts = [
            'aqs1004.eqiad.wmnet',
            'aqs1005.eqiad.wmnet',
            'aqs1006.eqiad.wmnet',
            'aqs1007.eqiad.wmnet',
            'aqs1008.eqiad.wmnet',
            'aqs1009.eqiad.wmnet'
        ]

        rsync::server::module { 'transfer_cassandra_a_tmp':
            ensure      => absent,
            path        => '/srv/cassandra-a/tmp',
            read_only   => 'no',
            list        => 'yes',
            hosts_allow => $aqs_hosts,
            auto_ferm   => true,
        }
        rsync::server::module { 'transfer_cassandra_b_tmp':
            ensure      => absent,
            path        => '/srv/cassandra-b/tmp',
            read_only   => 'no',
            list        => 'yes',
            hosts_allow => $aqs_hosts,
            auto_ferm   => true,
        }

        # Temporarily allow an-presto1001.eqiad.wmnet access to the cassandra
        # internode communication port to support loading by sstableloader
        ferm::service { 'cassandra-storage':
            ensure => absent,
            proto  => 'tcp',
            port   => '7000',
            srange => '(@resolve((an-presto1001.eqiad.wmnet)) @resolve((an-presto1001.eqiad.wmnet), AAAA))',
        }
    }
}
