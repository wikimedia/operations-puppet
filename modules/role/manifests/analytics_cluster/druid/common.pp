# == Class role::analytics_cluster::druid::common
# Installs the druid common package and common configuration settings.
# You will likely not have to include this class directly.
#
# Druid module parameters are configured via hiera.
#
# Druid Zookeeper settings will default to using the hosts in
# the hiera zookeeper_hosts hiera variable.  Druid Zookeeper chroot will
# be set according to $site in production, or $realm in labs.
#
class role::analytics_cluster::druid::common
{
    # Need Java before Druid is installed.
    require role::analytics_cluster::java

    $zookeeper_chroot = $::realm ? {
        'labs'       => "/druid/analytics-${::labsproject}",
        'production' => "/druid/analytics-${::site}",
    }

    $zookeeper_properties = {
        'druid.zk.service.host' =>
            join(keys(hiera(
                'zookeeper_hosts',
                # Default to running a single zk locally.
                {'localhost:2181' => {'id' => '1'}}
            )), ','),
        'druid.zk.paths.base'   => $zookeeper_chroot,
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
