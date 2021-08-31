class profile::mediawiki::maintenance::growthexperiments {
    # Purge old welcome survey data (personal data used in user options,
    # with 90-day retention) that's within 30 days of expiry, twice a month.
    # See T208369 and T252575. Logs are saved to
    # /var/log/mediawiki/mediawiki_job_growthexperiments-deleteOldSurveys/syslog.log
    profile::mediawiki::periodic_job { 'growthexperiments-deleteOldSurveys':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/deleteOldSurveys.php --cutoff 60',
        interval => '*-*-01,15 03:15:00',
    }

    # Ensure that a sufficiently large pool of link recommendations is available.
    profile::mediawiki::periodic_job { 'growthexperiments-refreshLinkRecommendations':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/refreshLinkRecommendations.php --verbose',
        interval => '*-*-* *:27:00',
    }

    # Track link recommendation pool size
    profile::mediawiki::periodic_job { 'growthexperiments-listTaskCounts':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/listTaskCounts.php --tasktype link-recommendation --topictype ores --statsd --output none',
        interval => '*-*-* *:11:00',
    }

    # update data for the mentor dashboard (T285811)
    profile::mediawiki::periodic_job { 'growthexperiments-updateMenteeData':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/updateMenteeData.php --statsd',
        interval => '*-*-* 04:15:00',
    }
}
