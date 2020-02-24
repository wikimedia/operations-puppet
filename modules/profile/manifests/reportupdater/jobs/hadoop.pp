# == Class profile::reportupdater::jobs::hadoop
# Installs reportupdater jobs that run on Hadoop/Hive.
# This profile should only be included in a single role.
#
# This requires that a Hadoop client is installed and the statistics compute role
# for the published_path.
class profile::reportupdater::jobs::hadoop(
    $ensure_jobs = lookup('profile::reportupdater::jobs::hadoop::ensure_jobs', { 'default_value' => 'present' }),
) {
    require ::profile::analytics::cluster::packages::hadoop
    require ::profile::analytics::cluster::client
    require ::statistics::compute

    $base_path = '/srv/reportupdater'

    # Set up reportupdater.
    # Reportupdater here launches Hadoop jobs, and
    # the 'analytics' user is the Analytics 'system' user that has
    # access to required files in Hadoop.
    class { 'reportupdater':
        user      => 'analytics',
        base_path => $base_path,
    }

    # And set up a link for periodic jobs to be included in published reports.
    # Because periodic is in published_path, files will be synced to
    # analytics.wikimedia.org/published/datasets/periodic/reports
    file { "${::statistics::compute::published_path}/datasets/periodic":
        ensure => 'directory',
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0775',
    }
    file { "${::statistics::compute::published_path}/datasets/periodic/reports":
        ensure  => 'link',
        target  => "${base_path}/output",
        require => Class['reportupdater'],
    }

    # Set up a job to create browser reports on hive db.
    reportupdater::job { 'browser':
        ensure     => $ensure_jobs,
        output_dir => 'metrics/browser',
    }

    reportupdater::job { 'interlanguage':
        ensure     => $ensure_jobs,
        output_dir => 'metrics/interlanguage',
    }

    reportupdater::job { 'pingback':
        ensure     => $ensure_jobs,
        output_dir => 'metrics/pingback',
    }

    reportupdater::job { 'published_cx2_translations':
        ensure      => $ensure_jobs,
        config_file => "${base_path}/jobs/reportupdater-queries/published_cx2_translations/config-hive.yaml",
        output_dir  => 'metrics/published_cx2_translations',
    }

    reportupdater::job { 'reference-previews':
        ensure     => $ensure_jobs,
        output_dir => 'metrics/reference-previews',
    }

    reportupdater::job { 'wmcs':
        ensure     => $ensure_jobs,
        output_dir => 'metrics/wmcs',
    }

    reportupdater::job { 'structured-data':
        ensure     => $ensure_jobs,
        output_dir => 'metrics/structured-data',
    }
}
