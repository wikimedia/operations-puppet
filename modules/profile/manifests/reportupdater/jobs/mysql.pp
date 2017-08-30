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
        repository => 'limn-flow-data',
        output_dir =>  'flow/datafiles',
    }
    reportupdater::job { 'flow-beta-features':
        repository => 'limn-flow-data',
        output_dir =>  'metrics/beta-feature-enables',
    }
    reportupdater::job { 'edit':
        repository => 'limn-edit-data',
        output_dir => 'metrics',
    }
    reportupdater::job { 'edit-beta-features':
        repository => 'limn-edit-data',
        output_dir => 'metrics/beta-feature-enables',
    }
    reportupdater::job { 'language':
        repository => 'limn-language-data',
        output_dir => 'metrics/beta-feature-enables',
    }
    reportupdater::job { 'ee':
        repository => 'limn-ee-data',
        output_dir => 'metrics/echo',
    }
    reportupdater::job { 'ee-beta-features':
        repository => 'limn-ee-data',
        output_dir => 'metrics/beta-feature-enables',
    }
    reportupdater::job { 'multimedia':
        repository => 'limn-multimedia-data',
        output_dir => 'metrics/multimedia-health',
    }
    reportupdater::job { 'ee-migration':
        repository => 'limn-ee-data',
        output_dir => 'metrics/ee',
    }
    reportupdater::job { 'interactive':
        repository => 'discovery-stats',
        output_dir => 'metrics/interactive',
    }
    reportupdater::job { 'page-creation':
        repository => 'reportupdater-queries',
        output_dir => 'metrics/page-creation',
    }
}