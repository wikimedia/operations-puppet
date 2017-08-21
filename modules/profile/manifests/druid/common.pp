# == Class profile::druid::common
# Installs the druid common package and common configuration settings.
# You will likely not have to include this class directly.
#
# Druid module parameters are configured via hiera.
#
# Druid Zookeeper settings will default to using the hosts in
# the hiera zookeeper_cluster_name and zookeeper_clusters hiera variables.
# Druid Zookeeper chroot will be set according to $site in production, or
# $labsproject in labs.
#
class profile::druid::common(
    $zookeeper_cluster_name = hiera('profile::druid::common::zookeeper_cluster_name'),
    $zookeeper_clusters     = hiera('zookeeper_clusters'),
    $druid_properties       = hiera_hash('druid::properties'),
    $use_cdh                = hiera('profile::druid::common::use_cdh')
) {
    # Need Java before Druid is installed.
    require ::profile::java::analytics

    $zookeeper_hosts = keys($zookeeper_clusters[$zookeeper_cluster_name]['hosts'])

    $zookeeper_chroot = $::realm ? {
        'labs'       => "/druid/analytics-${::labsproject}",
        'production' => "/druid/analytics-${::site}",
    }

    $zookeeper_properties   = {
        'druid.zk.paths.base'          => $zookeeper_chroot,
        'druid.discovery.curator.path' => "${zookeeper_chroot}/discovery",
        'druid.zk.service.host'        => join($zookeeper_hosts, ',')
    }

    # Druid Common Class
    class { '::druid':
        use_cdh => $use_cdh,
        # Merge our auto configured zookeeper properties
        # with the properties from hiera.
        properties => merge(
            $zookeeper_properties,
            $druid_properties
        ),
    }
}