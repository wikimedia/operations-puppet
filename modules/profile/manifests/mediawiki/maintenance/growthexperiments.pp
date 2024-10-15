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
    profile::mediawiki::maintenance::growthexperiments::refreshlinkrecommendations { [ 's1', 's2', 's3', 's4', 's5', 's6', 's7', 's8' ]: }

    # Track task pool size
    profile::mediawiki::periodic_job { 'growthexperiments-listTaskCounts':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/listTaskCounts.php --topictype ores --statsd --output none',
        interval => '*-*-* *:11:00',
    }

    # update data for the mentor dashboard (T285811)
    profile::mediawiki::maintenance::growthexperiments::updatementeedata { [ 's1', 's2', 's3', 's4', 's5', 's6', 's7', 's8' ]: }

    # monitor dangling link recommendation entries (DB record without search index record or vice versa)
    profile::mediawiki::periodic_job { 'growthexperiments-fixLinkRecommendationData-dryrun':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/fixLinkRecommendationData.php --search-index --db-table --dry-run --statsd',
        interval => '*-*-* 07:20:00',
    }
    # monitor eswiki and frwiki more closely to see the impact of changing the hook to clear outdated recommendations (T372337)
    profile::mediawiki::periodic_job { 'growthexperiments-fixLinkRecommendationData-dryrun-eswiki':
      command  => '/usr/local/bin/mwscript --wiki=eswiki extensions/GrowthExperiments/maintenance/fixLinkRecommendationData.php --search-index --db-table --dry-run --statsd',
      interval => '*-*-* *:10:00',
    }
    profile::mediawiki::periodic_job { 'growthexperiments-fixLinkRecommendationData-dryrun-frwiki':
      command  => '/usr/local/bin/mwscript --wiki=frwiki extensions/GrowthExperiments/maintenance/fixLinkRecommendationData.php --search-index --db-table --dry-run --statsd',
      interval => '*-*-* *:10:00',
    }

    # purge expired rows from the database (Mentor dashboard, T280307)
    profile::mediawiki::periodic_job { 'growthexperiments-purgeExpiredMentorStatus':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/purgeExpiredMentorStatus.php',
        interval => '*-*-01,15 8:45:00',
    }

    # push periodically-computed metrics into statsd (T318684)
    profile::mediawiki::periodic_job { 'growthexperiments-updateMetrics':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/updateMetrics.php --verbose',
        interval => '*-*-* 04:30:00',
    }

    # update user impact data (T313395)
    profile::mediawiki::periodic_job { 'growthexperiments-userImpactUpdateRecentlyRegistered':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/refreshUserImpactData.php --registeredWithin=2week --hasEditsAtLeast=3 --ignoreIfUpdatedWithin=6hour --verbose --use-job-queue',
        interval => '*-*-* 05:15:00',
    }
    profile::mediawiki::periodic_job { 'growthexperiments-userImpactUpdateRecentlyEdited':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/refreshUserImpactData.php --registeredWithin=1year --editedWithin=2week --hasEditsAtLeast=3 --ignoreIfUpdatedWithin=6hour --verbose --use-job-queue',
        interval => '*-*-* 07:45:00',
    }

    # delete old user impact data (T313395)
    profile::mediawiki::periodic_job { 'growthexperiments-userImpactDelete':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/deleteExpiredUserImpactData.php --expiry=2days',
        interval => '*-*-* 02:10:00',
    }

    # update the "is active" flag for mentees (T318457)
    profile::mediawiki::periodic_job { 'growthexperiments-updateIsActiveFlagForMentees':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/updateIsActiveFlagForMentees.php',
        interval => 'Mon *-*-* 09:42:00',
    }

    # update list of praiseworthy mentees (T322444)
    profile::mediawiki::periodic_job { 'growthexperiments-refreshPraiseworthyMentees':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/refreshPraiseworthyMentees.php',
        interval => '*-*-* 08:15:00',
    }
}
