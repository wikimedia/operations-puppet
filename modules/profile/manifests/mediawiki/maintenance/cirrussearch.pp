class profile::mediawiki::maintenance::cirrussearch(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    $team = 'search-platform'

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
        ensure   => absent, # Disable to replace with sharded periodic job
        command  => '/usr/local/bin/cirrus_build_completion_indices.sh eqiad',
        interval => '02:30',
    }

    profile::mediawiki::periodic_job { 'cirrus_build_completion_indices_codfw':
        ensure   => absent, # Disable to replace with sharded periodic job
        command  => '/usr/local/bin/cirrus_build_completion_indices.sh codfw',
        interval => '02:30',
    }

    profile::mediawiki::sharded_periodic_job { 'cirrus_build_completion_indices_eqiad':
        interval                  => '02:30',
        cron_schedule             => '30 02 * * *',
        shards                    => ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17'],
        script                    => 'extensions/CirrusSearch/maintenance/UpdateSuggesterIndex.php --masterTimeout=10m --replicationTimeout=5400  --indexChunkSize=3000 --cluster=eqiad --optimize',
        kubernetes                => true,
        team                      => $team,
        description               => 'Rebuild completion suggester indices daily',
        script_label              => 'UpdateSuggesterIndex.php-eqiad',
        helmfile_defaults_dir     => $helmfile_defaults_dir,
        foreachwiki_ignore_errors => true,
    }
    profile::mediawiki::sharded_periodic_job { 'cirrus_build_completion_indices_codfw':
        interval                  => '02:30',
        cron_schedule             => '30 02 * * *',
        shards                    => ['s1@11', 's2@12', 's3@13', 's4@14', 's5@15', 's6@16', 's7@17'],
        script                    => 'extensions/CirrusSearch/maintenance/UpdateSuggesterIndex.php --masterTimeout=10m --replicationTimeout=5400  --indexChunkSize=3000 --cluster=codfw --optimize',
        kubernetes                => true,
        team                      => $team,
        description               => 'Rebuild completion suggester indices daily',
        script_label              => 'UpdateSuggesterIndex.php-codfw',
        helmfile_defaults_dir     => $helmfile_defaults_dir,
        foreachwiki_ignore_errors => true,
    }
}
