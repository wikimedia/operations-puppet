# == Class profile::analytics::refinery::job::hdfs_cleaner
#
# Deletes files and empty directories older than 31 days from HDFS dirs:
#  - /tmp
#  - /wmf/tmp/analytics
#  - /wmf/tmp/druid
#
class profile::analytics::refinery::job::hdfs_cleaner(
    Wmflib::Ensure $ensure_timer  = lookup('profile::analytics::refinery::job::hdfs_cleaner::ensure_timer', { 'default_value' => 'present' }),
) {
    # Include refinery for HDFSCleaner class.
    require ::profile::analytics::refinery
    # Ensure hadoop client is installed (refinery conditionally includes this)
    Class['::profile::hadoop::common'] -> Class['::profile::analytics::refinery::job::hdfs_cleaner']

    $older_than_threshold = 2678400 # seconds in 31 days

    $command_tmp = "${::profile::analytics::refinery::path}/bin/hdfs-cleaner --path=/tmp --older_than_seconds=${older_than_threshold}"
    kerberos::systemd_timer { 'hdfs-cleaner-tmp':
        ensure          => $ensure_timer,
        description     => 'Run the HDFSCleaner job to keep HDFS /tmp dir clean of old files.',
        command         => $command_tmp,
        interval        => '*-*-* 23:00:00',
        logfile_name    => 'hdfs-cleaner-tmp.log',
        logfile_basedir => '/var/log/hadoop-hdfs',
        user            => 'hdfs',
    }

    $command_tmp_analytics = "${::profile::analytics::refinery::path}/bin/hdfs-cleaner --path=/wmf/tmp/analytics --older_than_seconds=${older_than_threshold}"
    kerberos::systemd_timer { 'hdfs-cleaner-tmp-analytics':
        ensure          => $ensure_timer,
        description     => 'Run the HDFSCleaner job to keep HDFS /wmf/tmp/analytics dir clean of old files.',
        command         => $command_tmp_analytics,
        interval        => '*-*-* 23:15:00',
        logfile_name    => 'hdfs-cleaner-tmp-analytics.log',
        logfile_basedir => '/var/log/hadoop-hdfs',
        user            => 'hdfs',
    }

    $command_tmp_druid = "${::profile::analytics::refinery::path}/bin/hdfs-cleaner --path=/wmf/tmp/druid --older_than_seconds=${older_than_threshold}"
    kerberos::systemd_timer { 'hdfs-cleaner-tmp-druid':
        ensure          => $ensure_timer,
        description     => 'Run the HDFSCleaner job to keep HDFS /wmf/tmp/druid dir clean of old files.',
        command         => $command_tmp_druid,
        interval        => '*-*-* 23:30:00',
        logfile_name    => 'hdfs-cleaner-tmp-druid.log',
        logfile_basedir => '/var/log/hadoop-hdfs',
        user            => 'hdfs',
    }
}
