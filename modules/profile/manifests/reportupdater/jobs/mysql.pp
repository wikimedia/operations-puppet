# == Class profile::reportupdater::jobs::mysql
#
# Installs reportupdater package, and sets up jobs that run reports and generate output from
# MySQL analytics slaves.  This profile should only be included in a single role.
#
# This requires the statistics module for the stats user and the published_datasets_path.
#
class profile::reportupdater::jobs::mysql {
    require statistics
    require statistics::compute
    require ::profile::analytics::cluster::packages::common

    # Set up reportupdater to be executed on this machine
    class { 'reportupdater':
        user      => $::statistics::user::username,
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
        target  => '/srv/reportupdater/output',
        require => Class['reportupdater'],
    }

    # Set up various jobs to be executed by reportupdater
    # creating several reports on mysql research db.
    reportupdater::job { 'flow':
        output_dir =>  'flow/datafiles',
    }
    reportupdater::job { 'flow-beta-features':
        output_dir =>  'metrics/beta-feature-enables',
    }
    reportupdater::job { 'edit-beta-features':
        output_dir => 'metrics/beta-feature-enables',
    }
    reportupdater::job { 'language':
        output_dir => 'metrics/beta-feature-enables',
    }
    reportupdater::job { 'published_cx2_translations':
        output_dir => 'metrics/published_cx2_translations',
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
    reportupdater::job { 'pingback':
        output_dir => 'metrics/pingback',
    }
}
