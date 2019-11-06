# == Class profile::hadoop::balancer
#
# Deletes files and empty directories older than 31 days from HDFS /tmp dir.
#
class profile::analytics::refinery::job::hdfs_cleaner(
    $use_kerberos = lookup('profile::analytics::refinery::job::hdfs_cleaner::use_kerberos', { 'default_value' => false }),
) {
    # Include refinery for HDFSCleaner class.
    require ::profile::analytics::refinery
    # Ensure hadoop client is installed (refinery conditionally includes this)
    Class['::profile::hadoop::common'] -> Class['::profile::analytics::refinery::job::hdfs_cleaner']

    $older_than_threshold = 2678400 # seconds in 31 days
    $command = "${::profile::analytics::refinery::path}/bin/hdfs-cleaner --path=/tmp --older_than_seconds=${older_than_threshold}"
    kerberos::systemd_timer { 'hdfs-cleaner':
        description     => 'Run the HDFSCleaner job to keep HDFS /tmp dir clean of old files.',
        command         => $command,
        interval        => '*-*-* 23:00:00',
        logfile_name    => 'hdfs-cleaner.log',
        logfile_basedir => '/var/log/hadoop-hdfs',
        user            => 'hdfs',
        use_kerberos    => $use_kerberos,
    }
}
