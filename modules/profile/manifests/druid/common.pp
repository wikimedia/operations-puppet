# SPDX-License-Identifier: Apache-2.0
# == Class profile::druid::common
# Installs the druid common package and common configuration settings.
#
# Druid module parameters are configured via hiera.
#
# You will likely not need to explicity include this module since it is
# a dependency of other ones like profile::druid::broker/etc..
#
# Druid Zookeeper settings will default to using the hosts in
# the hiera zookeeper_cluster_name and zookeeper_clusters hiera variables.
#
class profile::druid::common(
    String $druid_cluster_name             = lookup('profile::druid::common::druid_cluster_name'),
    String $zookeeper_cluster_name         = lookup('profile::druid::common::zookeeper_cluster_name'),
    Hash[String, Any] $private_properties  = lookup('profile::druid::common::private_properties', {'default_value' => {}}),
    Hash[String, Any] $properties          = lookup('profile::druid::common::properties', {'default_value' => {}}),
    Hash[String, Any] $zookeeper_clusters  = lookup('zookeeper_clusters'),
    String $metadata_storage_database_name = lookup('profile::druid::common:metadata_storage_database_name', {'default_value' => 'druid'}),
    Stdlib::Unixpath $java_home            = lookup('profile::druid::common::java_home', {'default_value' => '/usr/lib/jvm/java-8-openjdk-amd64'}),
    Boolean $use_hadoop_config             = lookup('profile::druid::common::use_hadoop_config', {'default_value' => true}),
) {

    # Need Java before Druid is installed.
    Class['profile::java'] -> Class['profile::druid::common']

    # Only need a Hadoop client if we are using CDH.
    if $use_hadoop_config {
        require ::profile::hadoop::common
    }

    $zookeeper_hosts        = keys($zookeeper_clusters[$zookeeper_cluster_name]['hosts'])
    $zookeeper_chroot       = "/druid/${druid_cluster_name}"
    $zookeeper_properties   = {
        'druid.zk.paths.base'          => $zookeeper_chroot,
        'druid.discovery.curator.path' => "${zookeeper_chroot}/discovery",
        'druid.zk.service.host'        => join($zookeeper_hosts, ',')
    }

    # Druid Common Class
    class { '::druid':
        metadata_storage_database_name => $metadata_storage_database_name,
        java_home                      => $java_home,
        # Merge our auto configured zookeeper properties
        # with the properties from hiera.
        properties                     => merge(
            $zookeeper_properties,
            $properties,
            $private_properties
        ),
    }
}
