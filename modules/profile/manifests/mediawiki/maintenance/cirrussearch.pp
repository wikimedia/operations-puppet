class profile::mediawiki::maintenance::cirrussearch {


    file { '/usr/local/bin/cirrus_build_completion_indices.sh':
        ensure => 'present',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/mediawiki/maintenance/cirrus_build_completion_indices.sh',
    }

    # Rebuilds the completion suggester indices daily. This job, as of
    # mar 2015, takes around 5 hours to run.
    profile::mediawiki::periodic_job { 'cirrus_build_completion_indices_eqiad':
        command  => '/usr/local/bin/cirrus_build_completion_indices.sh eqiad',
        interval => '02:30',
    }

    profile::mediawiki::periodic_job { 'cirrus_build_completion_indices_codfw':
        command  => '/usr/local/bin/cirrus_build_completion_indices.sh codfw',
        interval => '02:30',
    }

    profile::mediawiki::periodic_job { 'cirrus_saneitize_jobs':
        ensure   => present,
        # Saneitizer limited to private wikis, SUP handles all public wikis.
        command  => '/usr/local/bin/foreachwikiindblist private extensions/CirrusSearch/maintenance/SaneitizeJobs.php --push --refresh-freq=7200',
        interval => '0/2:10',
    }
}
