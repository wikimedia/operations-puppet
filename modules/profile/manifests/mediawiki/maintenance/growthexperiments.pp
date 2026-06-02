class profile::mediawiki::maintenance::growthexperiments(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    $team_name = 'growth'

    # Purge old welcome survey data (personal data used in user options,
    # with 90-day retention) that's within 30 days of expiry, twice a month.
    # See T208369 and T252575. Logs are saved to
    # /var/log/mediawiki/mediawiki_job_growthexperiments-deleteOldSurveys/syslog.log
    profile::mediawiki::periodic_job { 'growthexperiments-deleteOldSurveys':
        command                 => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/deleteOldSurveys.php --cutoff 60',
        interval                => '*-*-01,15 03:15:00',
        cron_schedule           => '15 3 1,15 * *',
        kubernetes              => true,
        team                    => $team_name,
        script_label            => 'deleteOldSurveys.php',
        description             => "Purge old welcome survey data (personal data used in user options, with 90-day retention) that's within 30 days of expiry, twice a month.",
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1814400, # 3 weeks
    }

    $link_rec_shards = [ 's1', 's2', 's3', 's4', 's5', 's6', 's7', 's8' ]

    # Cleanup as part of migration (T385782)
    $link_rec_shards.each |$shard| {
        profile::mediawiki::periodic_job { "growthexperiments-refreshLinkRecommendations-${shard}":
            command                 => "FOREACHWIKI_IGNORE_ERRORS=1 /usr/local/bin/foreachwikiindblist 'growthexperiments & ${shard}' extensions/GrowthExperiments/maintenance/refreshLinkRecommendations.php",
            interval                => '*-*-* *:27:00',
            cron_schedule           => '27 * * * *',
            kubernetes              => true,
            team                    => $team_name,
            script_label            => 'refreshLinkRecommendations.php',
            description             => 'Ensure that a sufficiently large pool of link recommendations is available.',
            concurrency_policy      => 'Forbid', # ensure that jobs finish - some shards can take multiple hours
            startingdeadlineseconds => 1800, # 30 minutes deadline to start a delayed job
            helmfile_defaults_dir   => $helmfile_defaults_dir,
        }
    }

    # Track task pool size
    profile::mediawiki::periodic_job { 'growthexperiments-listTaskCounts':
        command                 => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/listTaskCounts.php --topictype ores --statsd --output none',
        interval                => '*-*-* *:11:00',
        cron_schedule           => '11 * * * *',
        kubernetes              => true,
        team                    => $team_name,
        script_label            => 'listTaskCounts.php',
        description             => 'Track ores task pool size',
        concurrency_policy      => 'Forbid',
        startingdeadlineseconds => 1800, # 30 minutes deadline
        helmfile_defaults_dir   => $helmfile_defaults_dir,
    }

    # update data for the mentor dashboard (T285811)
    $update_mentee_shards = [ 's1', 's2', 's3', 's4', 's5', 's6', 's7', 's8' ]
    $update_mentee_shards.each | $mentee_shard | {
        profile::mediawiki::periodic_job { "growthexperiments-updateMenteeData-${mentee_shard}":
            command               => "/usr/local/bin/foreachwikiindblist 'growthexperiments & ${mentee_shard}' extensions/GrowthExperiments/maintenance/updateMenteeData.php --statsd --dbshard ${mentee_shard}",
            interval              => '*-*-* 00,03,06,09,12,15,18,21:15:00',
            cron_schedule         => '15 */3 * * *',
            kubernetes            => true,
            team                  => $team_name,
            script_label          => "updateMenteeData.php-${mentee_shard}",
            description           => 'update data for the mentor dashboard',
            helmfile_defaults_dir => $helmfile_defaults_dir,
        }
    }

    # monitor dangling link recommendation entries (DB record without search index record or vice versa)
    profile::mediawiki::periodic_job { 'growthexperiments-fixLinkRecommendationData-dryrun':
        command               => 'FOREACHWIKI_IGNORE_ERRORS=1 /usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/fixLinkRecommendationData.php --search-index --db-table --dry-run --statsd',
        interval              => '*-*-* 07:20:00',
        cron_schedule         => '20 7 * * *',
        kubernetes            => true,
        team                  => $team_name,
        script_label          => 'fixLinkRecommendationData.php-dryrun',
        description           => 'monitor dangling link recommendation entries (DB record without search index record or vice versa)',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    # purge expired rows from the database (Mentor dashboard, T280307)
    profile::mediawiki::periodic_job { 'growthexperiments-purgeExpiredMentorStatus':
        command                 => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/purgeExpiredMentorStatus.php',
        interval                => '*-*-01,15 8:45:00',
        cron_schedule           => '45 8 1,15 * *',
        kubernetes              => true,
        team                    => 'growth',
        script_label            => 'purgeExpiredMentorStatus.php',
        description             => 'Purge expired rows from the database for the Mentor dashboard, twice a month.',
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1814400, # 3 weeks
    }

    # push periodically-computed metrics into statsd (T318684)
    profile::mediawiki::periodic_job { 'growthexperiments-updateMetrics':
        command               => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/updateMetrics.php --verbose',
        interval              => '*-*-* 04:30:00',
        cron_schedule         => '30 4 * * *',
        kubernetes            => true,
        team                  => $team_name,
        script_label          => 'updateMetrics.php',
        description           => 'Push periodically-computed mentorship metrics into statsd (T318684)',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    # update user impact data (T313395)
    profile::mediawiki::periodic_job { 'growthexperiments-userImpactUpdateRecentlyRegistered':
        command               => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/refreshUserImpactData.php --registeredWithin=2week --hasEditsAtLeast=3 --ignoreIfUpdatedWithin=6hour --verbose --use-job-queue',
        interval              => '*-*-* 05:15:00',
        cron_schedule         => '15 5 * * *',
        kubernetes            => true,
        team                  => $team_name,
        script_label          => 'refreshUserImpactData.php-recentlyregistered',
        description           => 'update user impact data (recently registered users)',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
    profile::mediawiki::periodic_job { 'growthexperiments-userImpactUpdateRecentlyEdited':
        command               => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/refreshUserImpactData.php --registeredWithin=1year --editedWithin=2week --hasEditsAtLeast=3 --ignoreIfUpdatedWithin=6hour --verbose --use-job-queue',
        interval              => '*-*-* 07:45:00',
        cron_schedule         => '45 7 * * *',
        kubernetes            => true,
        team                  => $team_name,
        script_label          => 'refreshUserImpactData.php-recentlyedited',
        description           => 'update user impact data (recent edit users)',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    # delete old user impact data (T313395)
    profile::mediawiki::periodic_job { 'growthexperiments-userImpactDelete':
        command               => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/deleteExpiredUserImpactData.php --expiry=2days',
        interval              => '*-*-* 02:10:00',
        cron_schedule         => '10 2 * * *',
        kubernetes            => true,
        team                  => $team_name,
        script_label          => 'deleteExpiredUserImpactData.php',
        description           => 'Delete old user impact data (T313395)',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    profile::mediawiki::periodic_job { 'growthexperiments-updateIsActiveFlagForMentees':
        command                 => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/updateIsActiveFlagForMentees.php',
        interval                => 'Mon *-*-* 09:42:00',
        cron_schedule           => '42 9 * * MON',
        kubernetes              => true,
        team                    => $team_name,
        script_label            => 'updateIsActiveFlagForMentees.php',
        description             => 'update the "is active" flag for mentees (T318457)',
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1209600, # 2 weeks
    }

    profile::mediawiki::periodic_job { 'growthexperiments-refreshPraiseworthyMentees':
        command               => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/refreshPraiseworthyMentees.php',
        interval              => '*-*-* 08:15:00',
        cron_schedule         => '15 8 * * *',
        kubernetes            => true,
        team                  => $team_name,
        script_label          => 'refreshPraiseworthyMentees.php',
        description           => 'update list of praiseworthy mentees (T322444)',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    profile::mediawiki::periodic_job { 'growthexperiments-cleanMentorList':
        command               => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/growthexperiments.dblist extensions/GrowthExperiments/maintenance/cleanMentorList.php',
        interval              => '*-*-01/3 06:20:00',
        cron_schedule         => '20 6 */3 * *',
        kubernetes            => true,
        team                  => $team_name,
        script_label          => 'cleanMentorList.php',
        description           => 'Clean up the mentor list, every 3 days.',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
