# == Class profile::reportupdater::jobs
# Installs reportupdater jobs that run on Hadoop/Hive.
# This profile should only be included in a single role.
#
# This requires that a Hadoop client is installed and the statistics compute role
# for the published_path.
class profile::reportupdater::jobs {

    require ::profile::analytics::cluster::packages::hadoop
    require ::profile::analytics::cluster::client

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
        output_dir   => 'metrics/browser',
        use_kerberos => true,
    }

    reportupdater::job { 'interlanguage':
        output_dir   => 'metrics/interlanguage',
        use_kerberos => true,
    }

    reportupdater::job { 'pingback':
        output_dir   => 'metrics/pingback',
        use_kerberos => true,
    }

    reportupdater::job { 'reference-previews':
        output_dir   => 'metrics/reference-previews',
        use_kerberos => true,
    }

    reportupdater::job { 'wmcs':
        output_dir   => 'metrics/wmcs',
        use_kerberos => true,
    }

    reportupdater::job { 'structured-data':
        output_dir   => 'metrics/structured-data',
        use_kerberos => true,
    }

    # Set up various jobs to be executed by reportupdater
    # creating several reports on mysql research db.
    reportupdater::job { 'flow-beta-features':
        output_dir => 'metrics/beta-feature-enables',
    }

    reportupdater::job { 'edit-beta-features':
        output_dir => 'metrics/beta-feature-enables',
    }

    reportupdater::job { 'language':
        output_dir => 'metrics/beta-feature-enables',
    }

    # Note:
    # The published_cx2_translations jobs were on stat1007 (hive based)
    # and on stat1006 (mysql based). They now have different job names,
    # but their output directory is the same on purpose, to allow rsync
    # jobs to properly collect and merge data downstream.
    reportupdater::job { 'published_cx2_translations':
        config_file  => "${base_path}/jobs/reportupdater-queries/published_cx2_translations/config-hive.yaml",
        output_dir   => 'metrics/published_cx2_translations',
        use_kerberos => true,
    }
    reportupdater::job { 'published_cx2_translations_mysql':
        config_file => "${base_path}/jobs/reportupdater-queries/published_cx2_translations/config-mysql.yaml",
        output_dir  => 'metrics/published_cx2_translations',
        query_dir   => 'published_cx2_translations',
        interval    => '*-*-* *:30:00',
    }

    reportupdater::job { 'mt_engines':
        output_dir => 'metrics/mt_engines',
    }

    reportupdater::job { 'cx':
        output_dir => 'metrics/cx',
    }

    reportupdater::job { 'ee':
        output_dir => 'metrics/echo',
    }

    reportupdater::job { 'ee-beta-features':
        output_dir => 'metrics/beta-feature-enables',
    }

    reportupdater::job { 'page-creation':
        output_dir => 'metrics/page-creation',
    }
}
