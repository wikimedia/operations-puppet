# == Class profile::aqs
# Analytics Query Service Restbase Service configuration
#
class profile::aqs (
        $monitoring_enabled            = hiera('profile::aqs::monitoring_enabled'),
        $druid_host                    = hiera('profile::aqs::druid_host'),
        $druid_query_path              = hiera('profile::aqs::druid_query_path'),
        $cassandra_user                = hiera('profile::aqs::cassandra_user'),
        $cassandra_seeds               = hiera('profile::aqs::seeds'),
        $logstash_host                 = hiera('profile::aqs::logstash_host'),
        $cassandra_default_consistency = hiera('profile::aqs::cassandra_default_consistency'),
        $statsd_host                   = hiera('profile::aqs::statsd_host'),
){
    require ::passwords::aqs

    class { '::aqs':
        cassandra_user                => $cassandra_user,
        cassandra_user                => $passwords::aqs::aqs_user,
        druid_host                    => $druid_host,
        druid_query_path              => $druid_query_path,
        seeds                         => $cassandra_seeds,
        cassandra_default_consistency => $cassandra_default_consistency,
        cassandra_local_dc            => $::site,
        statsd_host                   => $statsd_host,
    }

    ferm::service {'aqs_web':
        proto => 'tcp',
        port  => $::aqs::port,
    }

    if $monitoring_enabled {
        monitoring::service { 'aqs_http_root':
            description   => 'AQS root url',
            check_command => "check_http_port_url!${::aqs::port}!/",
            contact_group => 'admins,team-services',
        }
        #TODO: add monitoring once we figure out what metrics we want
        #monitoring::graphite_threshold { 'restbase_analytics_<<some-metric-name>>':
            #description   => 'Analytics RESTBase req/s returning 5xx http://grafana.wikimedia.org/#/dashboard/db/restbase',
            #metric        => '<<the metric and any transformations>>',
            #from          => '10min',
            #warning       => '<<warning threshold>>', # <<explain>>
            #critical      => '<<critical threshold>>', # <<explain>>
            #percentage    => '20',
            #contact_group => 'aqs-admins',
        #}
    }

}