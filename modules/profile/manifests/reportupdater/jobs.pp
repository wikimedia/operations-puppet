# == Class profile::reportupdater::jobs
# Installs reportupdater jobs that run on Hadoop/Hive.
# This profile should only be included in a single role.
#
# This requires that a Hadoop client is installed and the statistics compute role
# for the published_path.
class profile::reportupdater::jobs (
    # Absent all report-updater jobs as they have been migrated to Airflow
    # TODO: Remove report-updater code when we're sure we won't need it anymore
    $ensure_jobs = lookup('profile::reportupdater::jobs::ensure_jobs', { 'default_value' => 'absent' }),
) {
    require profile::analytics::cluster::packages::common
    require profile::analytics::cluster::client

    $base_path = '/srv/reportupdater'
    $log_path = "${base_path}/log"
    $user = 'analytics'

    # Set up reportupdater.
    # Reportupdater here launches Hadoop jobs, and
    # the 'analytics' user is the Analytics 'system' user that has
    # access to required files in Hadoop.
    class { 'reportupdater':
        user      => $user,
        base_path => $base_path,
        log_path  => $log_path,
    }

    # Setup timer for rsyncing logs to HDFS.
    $hdfs_log_path = '/tmp/reportupdater-logs'

    bigtop::hadoop::directory { $hdfs_log_path:
        ensure => absent,
        owner  => $user,
        group  => $user,
        mode   => '0755',
    }

    kerberos::systemd_timer { 'analytics-reportupdater-logs-rsync':
        ensure      => absent,
        description => 'Rsync reportupdater logs to HDFS.',
        command     => "/usr/local/bin/hdfs-rsync -r -t --delete --perms file://${log_path} hdfs://${hdfs_log_path}",
        interval    => '*-*-* *:30:00',
        user        => $user,
        require     => Bigtop::Hadoop::Directory[$hdfs_log_path],
    }

    # And set up a link for periodic jobs to be included in published reports.
    # Because periodic is in published_path, files will be synced to
    # analytics.wikimedia.org/published/datasets/periodic/reports
    file { "${facts['statistics::compute::published_path']}/datasets/periodic":
        ensure => absent,
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0775',
    }
    file { "${facts['statistics::compute::published_path']}/datasets/periodic/reports":
        ensure  => absent,
        target  => "${base_path}/output",
        require => Class['reportupdater'],
    }
}
