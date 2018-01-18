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
    $druid_cluster_name             = hiera('profile::druid::common::druid_cluster_name'),
    $zookeeper_cluster_name         = hiera('profile::druid::common::zookeeper_cluster_name'),
    $private_properties             = hiera('profile::druid::common::private_properties', {}),
    $properties                     = hiera('profile::druid::common::properties', {}),
    $zookeeper_clusters             = hiera('zookeeper_clusters'),
    $metadata_storage_database_name = hiera('profile::druid::common:metadata_storage_database_name', 'druid'),
    $use_cdh                        = hiera('profile::druid::common::use_cdh', false),
) {
    # Need Java before Druid is installed.
    require ::profile::java::analytics

    # Only need a Hadoop client if we are using CDH.
    if $use_cdh {
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
        use_cdh                        => $use_cdh,
        # Merge our auto configured zookeeper properties
        # with the properties from hiera.
        properties                     => merge(
            $zookeeper_properties,
            $properties,
            $private_properties
        ),
    }
}
