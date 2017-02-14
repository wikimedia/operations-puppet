# (stat1003)
class role::statistics::cruncher inherits role::statistics::base {
    system::role { 'role::statistics::cruncher':
        description => 'Statistics general compute node (non private data)'
    }

    include standard
    include base::firewall
    include role::backup::host
    backup::set { 'home' : }

    statistics::mysql_credentials { 'research':
        group => 'researchers',
    }

    # include stuff common to statistics compute nodes
    include ::statistics::compute

    # rsync logs from logging hosts
    include ::statistics::rsync::eventlogging


    # geowiki: bringing data from production slave db to research db
    include geowiki::job::data
    # geowiki: generate limn files from research db and push them
    include geowiki::job::limn
    # geowiki: monitors the geowiki files of http://gp.wmflabs.org/
    include geowiki::job::monitoring


    # Set up reportupdater to be executed on this machine
    class { 'reportupdater':
        base_path => "${::statistics::working_path}/reportupdater",
        user      => $::statistics::user::username,
    }
    # And set up a link for periodic jobs to be included in published reports.
    # Because periodic is in published_datasets_path, files will be synced to
    # analytics.wikimedia.org/datasets/periodic
    file { "${::statistics::compute::published_datasets_path}/periodic":
        ensure  => 'link',
        target  => "${::statistics::working_path}/reportupdater/output",
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
}
