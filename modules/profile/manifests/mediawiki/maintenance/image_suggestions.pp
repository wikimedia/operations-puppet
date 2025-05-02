# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::image_suggestions(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {

    $team_name = 'structured-data'

    profile::mediawiki::periodic_job { 'ImageSuggestions_NotifyUnillustratedWatched_CA':
        command               => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=cawiki --min-edit-count=500 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --queue --quiet',
        interval              => 'Wed 0:00',
        cron_schedule         => '0 0 * * WED',
        kubernetes            => true,
        team                  => $team_name,
        script_label          => 'SendNotificationsForUnillustratedWatchedTitles.php-cawiki',
        description           => 'Send notifications about image suggestions for cawiki once a week on wednesdays',
        migration_title       => 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_CA',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    profile::mediawiki::periodic_job { 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_NO':
        command  => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=nowiki --min-edit-count=500 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --queue --quiet',
        interval => 'Wed 1:00',
    }

    profile::mediawiki::periodic_job { 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_PT':
        command  => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=ptwiki --min-edit-count=300 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --queue --quiet',
        interval => 'Wed 2:00',
    }

    profile::mediawiki::periodic_job { 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_RU':
        command  => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=ruwiki --min-edit-count=500 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --queue --quiet',
        interval => 'Wed 3:00',
    }

    profile::mediawiki::periodic_job { 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_ID':
        command  => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=idwiki --min-edit-count=500 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --queue --quiet',
        interval => 'Wed 4:00',
    }

    profile::mediawiki::periodic_job { 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_FI':
        command  => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=fiwiki --min-edit-count=500 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --queue --quiet',
        interval => 'Wed 5:00',
    }

    profile::mediawiki::periodic_job { 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_HU':
        command  => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=huwiki --min-edit-count=500 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --queue --quiet',
        interval => 'Wed 6:00',
    }
}
