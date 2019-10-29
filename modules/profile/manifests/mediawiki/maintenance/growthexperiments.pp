class profile::mediawiki::maintenance::growthexperiments {
    # Purge old welcome survey data (personal data used in user options,
    # with a 360-day retention exception) that's within 30 days of expiry,
    # twice a month. See T208369. Logs are saved to
    # /var/log/mediawiki/mediawiki_job_growthexperiments-deleteOldSurveys/syslog.log
    profile::mediawiki::periodic_job { 'growthexperiments-deleteOldSurveys':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/deleteOldSurveys.php --cutoff 335',
        interval => '*-*-1,15 3:15:00',
    }
}
