# Bugzilla server - http://wikitech.wikimedia.org/view/Bugzilla

class misc::bugzilla::server {

	system_role { "misc::bugzilla::server": description => "Bugzilla server" }

	class {'webserver::php5': ssl => 'true'; }

	apache_site { bugzilla: name => "bugzilla.wikimedia.org" }
	file {
		"/etc/apache2/sites-available/bugzilla.wikimedia.org":
			source => "puppet:///files/apache/sites/bugzilla.wikimedia.org",
			mode => 0444,
			owner => root,
			group => www-data;
	}
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

# RT-3962 - mail bz user stats to community metrics
class misc::bugzilla::communitymetrics {

	file { bugzilla_communitymetrics_file:
		path => "/srv/org/wikimedia/bugzilla/bugzilla_community_metrics.sh",
		owner => root,
		group => www-data,
		mode => 0550,
		source => "puppet:///files/misc/bugzilla_community_metrics.sh",
		ensure => present,
	}

	cron { bugzilla_communitymetrics_cron:
		command	=> "cd /srv/org/wikimedia/bugzilla/ ; ./bugzilla_community_metrics.sh",
		user => www-data,
		hour => 0,
		minute => 0,
		monthday => 1,
	}
}

class misc::bugzilla::report {

	systemuser { bzreporter: name => 'reporter', home => '/home/reporter', groups => [ 'reporter' ] }

	require passwords::bugzilla

	file { bugzilla_report:
		path => "/home/reporter/bugzilla_report.php",
		owner => reporter,
		group => reporter,
		mode => 0550,
		content => template('misc/bugzilla_report.php');
		ensure => present,
	}

}
