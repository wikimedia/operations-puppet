# == Class profile::analytic::cluster::hdfs_mount
#
# Include a FUSE mountpoint under /mnt/hdfs to access HDFS.
#
class profile::analytics::cluster::hdfs_mount(
    $monitoring_enabled = lookup('profile::analytics::cluster::hdfs_mount::monitoring_enabled', { 'default_value' => true }),
    $kerberos_enabled = lookup('profile::analytics::cluster::hdfs_mount::kerberos_enabled', { 'default_value' => false }),
    $monitoring_user = lookup('profile::analytics::cluster::hdfs_mount::monitoring_user', { 'default_value' => 'analytics' }),
) {
    # Include Hadoop ecosystem client classes.
    require ::profile::hadoop::common

    # Mount HDFS via Fuse on Analytics client nodes.
    # This will mount HDFS at /mnt/hdfs read only.
    class { '::cdh::hadoop::mount': }

    if $monitoring_enabled {
        if $kerberos_enabled {
            require ::profile::kerberos::client

            # The following requires a keytab for the analytics user deployed on the host.
            $kerberos_prefix = "/usr/bin/sudo -u ${monitoring_user} ${::profile::kerberos::client::run_command_script} ${monitoring_user} "
            sudo::user { 'nagios-check_hadoop_mount_readability':
                user       => 'nagios',
                privileges => ["ALL = (${monitoring_user}) NOPASSWD: ${::profile::kerberos::client::run_command_script} ${monitoring_user} /usr/local/lib/nagios/plugins/check_mountpoint_readability ${cdh::hadoop::mount::mount_point}"],
            }
        } else {
            $kerberos_prefix = ''
        }

        file { '/usr/local/lib/nagios/plugins/check_mountpoint_readability':
            ensure => present,
            source => 'puppet:///modules/profile/analytics/check_mountpoint_readability',
            mode   => '0555',
            owner  => 'root',
            group  => 'root',
        }
        nrpe::monitor_service { 'check_hadoop_mount_readability':
            description    => 'Check if the Hadoop HDFS Fuse mountpoint is readable',
            nrpe_command   => "${kerberos_prefix}/usr/local/lib/nagios/plugins/check_mountpoint_readability ${cdh::hadoop::mount::mount_point}",
            check_interval => 30,
            retries        => 2,
            contact_group  => 'analytics',
            require        => File['/usr/local/lib/nagios/plugins/check_mountpoint_readability'],
            notes_url      => 'https://wikitech.wikimedia.org/wiki/Analytics/Systems/Cluster/Hadoop/Administration#Fixing_HDFS_mount_at_/mnt/hdfs',
        }
    }
}
