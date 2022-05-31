# == Class profile::analytic::cluster::hdfs_mount
#
# Include a FUSE mountpoint under /mnt/hdfs to access HDFS.
#
class profile::analytics::cluster::hdfs_mount(
    $monitoring_enabled = lookup('profile::analytics::cluster::hdfs_mount::monitoring_enabled', { 'default_value' => false }),
    $kerberos_enabled = lookup('profile::analytics::cluster::hdfs_mount::kerberos_enabled', { 'default_value' => true }),
    $monitoring_user = lookup('profile::analytics::cluster::hdfs_mount::monitoring_user', { 'default_value' => 'analytics-privatedata' }),
) {
    # Include Hadoop ecosystem client classes.
    require ::profile::hadoop::common

    # Mount HDFS via Fuse on Analytics client nodes.
    # This will mount HDFS at /mnt/hdfs read only.
    class { '::bigtop::hadoop::mount': }

    if $monitoring_enabled {
        if $kerberos_enabled {
            require ::profile::kerberos::client

            # The following requires a keytab for the analytics user deployed on the host.
            $sudo_user = $monitoring_user
            $kerberos_prefix = "${::profile::kerberos::client::run_command_script} ${monitoring_user} "

            sudo::user { 'nagios-check_hadoop_mount_readability':
                ensure => absent,
            }
        } else {
            $sudo_user = undef
            $kerberos_prefix = ''
        }

        nrpe::plugin { 'check_mountpoint_readability':
            source => 'puppet:///modules/profile/analytics/check_mountpoint_readability',
        }

        nrpe::monitor_service { 'check_hadoop_mount_readability':
            description    => 'Check if the Hadoop HDFS Fuse mountpoint is readable',
            nrpe_command   => "${kerberos_prefix}/usr/local/lib/nagios/plugins/check_mountpoint_readability ${bigtop::hadoop::mount::mount_point}",
            sudo_user      => $sudo_user,
            check_interval => 30,
            retries        => 2,
            contact_group  => 'analytics',
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration#Fixing_HDFS_mount_at_/mnt/hdfs',
        }
    }
}
