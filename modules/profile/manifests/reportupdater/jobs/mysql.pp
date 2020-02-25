# == Class profile::reportupdater::jobs::mysql
#
# Installs reportupdater package, and sets up jobs that run reports and generate output from
# MySQL analytics slaves.  This profile should only be included in a single role.
#
# This requires the statistics module for the stats user and the published_path.
#
class profile::reportupdater::jobs::mysql {
    require statistics
    require statistics::compute
    require ::profile::analytics::cluster::packages::common

    $base_path = '/srv/reportupdater'

    # Set up reportupdater to be executed on this machine
    class { 'reportupdater':
        user      => $::statistics::user::username,
        base_path => $base_path,
    }

    # And set up a link for periodic jobs to be included in published reports.
    # Because datasets/periodic is in published_path, files will be synced to
    # analytics.wikimedia.org/datasets/periodic/reports
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

    # Set up various jobs to be executed by reportupdater
    # creating several reports on mysql research db.
    reportupdater::job { 'flow-beta-features':
        ensure     => absent,
        output_dir => 'metrics/beta-feature-enables',
    }
    reportupdater::job { 'edit-beta-features':
        ensure     => absent,
        output_dir => 'metrics/beta-feature-enables',
    }
    reportupdater::job { 'language':
        ensure     => absent,
        output_dir => 'metrics/beta-feature-enables',
    }
    reportupdater::job { 'published_cx2_translations':
        ensure      => absent,
        config_file => "${base_path}/jobs/reportupdater-queries/published_cx2_translations/config-mysql.yaml",
        output_dir  => 'metrics/published_cx2_translations',
    }
    reportupdater::job { 'mt_engines':
        ensure     => absent,
        output_dir => 'metrics/mt_engines',
    }
    reportupdater::job { 'cx':
        ensure     => absent,
        output_dir => 'metrics/cx',
    }
    reportupdater::job { 'ee':
        ensure     => absent,
        output_dir => 'metrics/echo',
    }
    reportupdater::job { 'ee-beta-features':
        ensure     => absent,
        output_dir => 'metrics/beta-feature-enables',
    }
    reportupdater::job { 'page-creation':
        ensure     => absent,
        output_dir => 'metrics/page-creation',
    }
}
