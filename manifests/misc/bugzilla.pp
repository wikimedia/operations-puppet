# Bugzilla server - http://wikitech.wikimedia.org/view/Bugzilla

class misc::bugzilla::server {

	system_role { "misc::bugzilla::server": description => "Bugzilla server" }

	class {'generic::webserver::php5': ssl => 'true'; }

	apache_site { bugzilla: name => "bugzilla.wikimedia.org" }
}

class misc::bugzilla::crons {
	cron { bugzilla_whine:
		command => "cd /srv/org/wikimedia/bugzilla/ ; ./whine.pl",
		user => root,
		minute => 15
	}

	# 2 cron jobs to generate charts data
	# See https://bugzilla.wikimedia.org/29203
	# 1) get statistics for the day:
	cron { bugzilla_collectstats:
		command => "cd /srv/org/wikimedia/bugzilla/ ; ./collectstats.pl",
		user    => root,
		hour    => 0,
		minute  => 5,
		weekday => [ 1, 2, 3, 4, 5, 6 ] # Monday - Saturday
	}
	# 2) on sunday, regenerates the whole statistics data
	cron { bugzilla_collectstats_regenerate:
		command => "cd /srv/org/wikimedia/bugzilla/ ; ./collectstats.pl --regenerate",
		user    => root,
		hour    => 0,
		minute  => 5,
		weekday => 0  # Sunday
	}
}
