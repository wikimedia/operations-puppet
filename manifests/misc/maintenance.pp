# misc/maintenance.pp

# mw maintenance/batch hosts

class misc::maintenance::foundationwiki {

	system_role { "misc::maintenance::foundationwiki": description => "Misc - Maintenance Server: foundationwiki" }

	cron { 'updatedays':
		user => apache,
		minute => '*/15',
		command => '/usr/local/bin/mwscript extensions/ContributionReporting/PopulateFundraisingStatistics.php foundationwiki --op updatedays > /tmp/PopulateFundraisingStatistics-updatedays.log',
		ensure => present,
	}

	cron { 'populatefundraisers':
		user => apache,
		minute => 5,
		command => '/usr/local/bin/mwscript extensions/ContributionReporting/PopulateFundraisingStatistics.php foundationwiki --op populatefundraisers > /tmp/PopulateFundraisingStatistics-populatefundraisers.log',
		ensure => present,
	}
}

class misc::maintenance::refreshlinks {

	require mediawiki

	# Include this to add cron jobs calling refreshLinks.php on all clusters. (RT-2355)

	file { '/home/mwdeploy/refreshLinks':
		ensure => directory,
		owner => mwdeploy,
		group => mwdeploy,
		mode => 0664,
	}

	define cronjob() {

		$cluster = regsubst($name, '@.*', '\1')
		$monthday = regsubst($name, '.*@', '\1')

		cron { "cron-refreshlinks-${name}":
			command => "/usr/local/bin/mwscriptwikiset refreshLinks.php ${cluster}.dblist --dfn-only > /home/mwdeploy/refreshLinks/${name}.log 2>&1",
			user => mwdeploy,
			hour => 0,
			minute => 0,
			monthday => $monthday,
			ensure => present,
		}
	}

	# add cron jobs - usage: <cluster>@<day of month> (these are just needed monthly) (note: s1 is temp. deactivated)
	cronjob { ['s2@2', 's3@3', 's4@4', 's5@5', 's6@6', 's7@7']: }
}

class misc::maintenance::pagetriage {

	system_role { "misc::maintenance::pagetriage": description => "Misc - Maintenance Server: pagetriage extension" }

	cron { 'pagetriage_cleanup':
		user => apache,
		minute => 55,
		hour => 20,
		monthday => '*/2',
		command => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php',
		ensure => present,
	}
}
