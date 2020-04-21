class profile::mediawiki::maintenance::cirrussearch {
    # Rebuilds the completion suggester indices daily. The `|| true` statement
    # ensures one failing wiki doesn't fail the entire job. This job, as of
    # mar 2015, takes around 5 hours to run.
    profile::mediawiki::periodic_job { 'cirrus_build_completion_indices_eqiad':
        command  => '/usr/local/bin/expanddblist all | xargs -I{} -P 4 sh -c \'/usr/local/bin/mwscript extensions/CirrusSearch/maintenance/UpdateSuggesterIndex.php --wiki={} --masterTimeout=10m --replicationTimeout=5400 --indexChunkSize 3000 --cluster=eqiad --optimize || true\'',
        interval => '02:30',
    }

    profile::mediawiki::periodic_job { 'cirrus_build_completion_indices_codfw':
        command  => '/usr/local/bin/expanddblist all | xargs -I{} -P 4 sh -c \'/usr/local/bin/mwscript extensions/CirrusSearch/maintenance/UpdateSuggesterIndex.php --wiki={} --masterTimeout=10m --replicationTimeout=5400 --indexChunkSize 3000 --cluster=codfw --optimize || true\'',
        interval => '02:30',
    }

    profile::mediawiki::periodic_job { 'cirrus_sanitize_jobs':
        command  => '/usr/local/bin/foreachwiki extensions/CirrusSearch/maintenance/SaneitizeJobs.php --push --refresh-freq=7200',
        interval => '0/2:10',
    }
}
