# == Class role::analytics_cluster::druid::common
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
class role::analytics_cluster::druid::common
{
    # Need Java before Druid is installed.
    require ::role::analytics_cluster::java

    $zookeeper_cluster_name = hiera('zookeeper_cluster_name')
    $zookeeper_clusters     = hiera('zookeeper_clusters')
    $zookeeper_hosts        = join(keys($zookeeper_clusters[$zookeeper_cluster_name]['hosts']), ',')

    $zookeeper_chroot = $::realm ? {
        'labs'       => "/druid/analytics-${::labsproject}",
        'production' => "/druid/analytics-${::site}",
    }

    $zookeeper_properties   = {
        'druid.zk.paths.base'          => $zookeeper_chroot,
        'druid.discovery.curator.path' => "${zookeeper_chroot}/discovery",
        'druid.zk.service.host'        => $zookeeper_hosts,
    }

    # Look up druid::properties out of hiera.  Since class path
    # lookup does not do hiera hash merging, we do so manually here.
    $hiera_druid_properties = hiera_hash('druid::properties', {})

    # Druid Common Class
    class { '::druid':
        # Merge our auto configured zookeeper properties
        # with the properties from hiera.
        properties => merge(
            $zookeeper_properties,
            $hiera_druid_properties
        ),
    }
}
