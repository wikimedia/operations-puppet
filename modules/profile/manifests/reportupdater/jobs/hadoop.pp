# == Class profile::reportupdater::jobs::hadoop
# Installs reportupdater jobs that run on Hadoop/Hive.
# This profile should only be included in a single role.
#
# This requires that a Hadoop client is installed and the statistics compute role
# for the published_datasets_path.
class profile::reportupdater::jobs::hadoop {
    # TODO: it would be better to depend on role::analytics_cluster::client, but
    # that seems wrong from a profile.  Perhaps when analytics_cluster roles
    # have been refactored to profiles.
    Class['cdh::hadoop'] -> Class['profile::reportupdater::jobs::hadoop']

    require ::statistics::compute

    # Set up reportupdater.
    # Reportupdater here launches Hadoop jobs, and
    # the 'hdfs' user is the only 'system' user that has
    # access to required files in Hadoop.
    class { 'reportupdater':
        user      => 'hdfs',
        base_path => '/srv/reportupdater',
    }

    # And set up a link for periodic jobs to be included in published reports.
    # Because periodic is in published_datasets_path, files will be synced to
    # analytics.wikimedia.org/datasets/periodic/reports
    file { "${::statistics::compute::published_datasets_path}/periodic":
        ensure => 'directory',
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0775',
    }
    file { "${::statistics::compute::published_datasets_path}/periodic/reports":
        ensure  => 'link',
        target  => "${base_path}/output",
        require => Class['reportupdater'],
    }

    # Set up a job to create browser reports on hive db.
    reportupdater::job { 'browser':
        repository => 'reportupdater-queries',
        output_dir => 'metrics/browser',
    }
}
