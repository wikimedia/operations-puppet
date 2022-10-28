# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::image_suggestions {
  profile::mediawiki::periodic_job { 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_CA':
    command  => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=cawiki --min-edit-count=500 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --quiet',
    interval => 'Wed 0:00',
  }

  profile::mediawiki::periodic_job { 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_NO':
    command  => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=nowiki --min-edit-count=500 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --quiet',
    interval => 'Wed 1:00',
  }

  profile::mediawiki::periodic_job { 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_PT':
    command  => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=ptwiki --min-edit-count=300 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --quiet',
    interval => 'Wed 2:00',
  }

  profile::mediawiki::periodic_job { 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_RU':
    command  => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=ruwiki --min-edit-count=500 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --quiet',
    interval => 'Wed 3:00',
  }

  profile::mediawiki::periodic_job { 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_ID':
    command  => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=idwiki --min-edit-count=500 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --quiet',
    interval => 'Wed 4:00',
  }

  profile::mediawiki::periodic_job { 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_FI':
    command  => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=fiwiki --min-edit-count=500 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --quiet',
    interval => 'Wed 5:00',
  }

  profile::mediawiki::periodic_job { 'ImageSuggestions_SendNotificationsForUnillustratedWatchedTitles_HU':
    command  => '/usr/local/bin/mwscript extensions/ImageSuggestions/maintenance/SendNotificationsForUnillustratedWatchedTitles.php --wiki=huwiki --min-edit-count=500 --min-confidence=80 --max-notifications-per-user=2 --exclude-instance-of=Q5 --quiet',
    interval => 'Wed 6:00',
  }
}
