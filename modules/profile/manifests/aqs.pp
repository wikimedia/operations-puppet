# == Class profile::aqs
# Analytics Query Service Restbase Service configuration
#
class profile::aqs (
        $monitoring_enabled            = hiera('profile::aqs::monitoring_enabled', false),
        $druid_properties              = hiera('profile::aqs::druid_properties', undef),
        $druid_datasources             = hiera('profile::aqs::druid_datasources', undef),
        $druid_uri_pattern             = hiera('profile::aqs::druid_uri_pattern'),
        $cassandra_user                = hiera('profile::aqs::cassandra_user'),
        $cassandra_password            = hiera('profile::aqs::cassandra_password'),
        $cassandra_seeds               = hiera('profile::aqs::seeds'),
        $logstash_host                 = hiera('logstash_host', undef),
        $cassandra_default_consistency = hiera('profile::aqs::cassandra_default_consistency'),
        $cassandra_local_dc            = hiera('profile::aqs::cassandra_local_dc'),
        $statsd_host                   = hiera('profile::aqs::statsd_host', undef),
        $use_nodejs10                  = hiera('profile::aqs::use_nodejs10', false),
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
        logstash_host                 => $logstash_host,
        use_nodejs10                  => $use_nodejs10,
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
            #description   => 'Analytics RESTBase req/s returning 5xx http://grafana.wikimedia.org/#/dashboard/db/restbase',
            #metric        => '<<the metric and any transformations>>',
            #from          => '10min',
            #warning       => <<warning threshold>>, # <<explain>>
            #critical      => <<critical threshold>>, # <<explain>>
            #percentage    => 20,
            #contact_group => 'aqs-admins',
            #notes_link     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/AQS#Monitoring',
        #}
    }

}
