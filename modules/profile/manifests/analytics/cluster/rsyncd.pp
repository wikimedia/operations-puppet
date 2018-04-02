# == Class profile::analytics::cluster::rsyncd
#
# Set up an rsync module at certain paths to
# allow read only rsync access to analytics generated data.
#
class profile::analytics::cluster::rsyncd(
    $hosts_allow = hiera('statistics_servers'),
) {
    # This will allow $hosts_allow to host public data files
    # generated by the analytics cluster.
    # Note that this requires that cdh::hadoop::mount
    # be present and mounted at /mnt/hdfs
    rsync::server::module { 'hdfs-archive':
        path        => "${::cdh::hadoop::mount::mount_point}/wmf/data/archive",
        read_only   => 'yes',
        list        => 'yes',
        hosts_allow => $hosts_allow,
        require     => Class['cdh::hadoop::mount'],
    }

    # Allows $hosts_allow to read locally generated datasets
    # that are served as part of Wikimedia dumps
    rsync::server::module { 'dumps':
        path        => '/srv/dumps',
        read_only   => 'yes',
        list        => 'yes',
        hosts_allow => $hosts_allow,
        require     => File['/srv/dumps'],
    }

    $hosts_allow_ferm = join($hosts_allow, ' ')
    ferm::service {'analytics_rsyncd_hdfs_archive':
        port   => '873',
        proto  => 'tcp',
        srange => "@resolve((${hosts_allow_ferm}))",
    }
}
