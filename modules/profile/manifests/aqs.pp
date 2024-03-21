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
        git_deploy                    => $git_deploy,
    }

    ferm::service {'aqs_web':
        proto => 'tcp',
        port  => $::aqs::port,
    }

    monitoring::service { 'aqs_http_root':
        ensure        => stdlib::ensure($monitoring_enabled),
        description   => 'AQS root url',
        check_command => "check_http_port_url!${::aqs::port}!/",
        contact_group => 'admins,team-services,team-data-platform',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/AQS#Monitoring',
    }
}
