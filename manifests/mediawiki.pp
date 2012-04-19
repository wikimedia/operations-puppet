# mediawiki.pp

class mediawiki::packages {
	package { wikimedia-task-appserver:
		ensure => latest;
	}
}

class mediawiki::sync {
	# Include this for syncinc mw installation
	# Include apache::apache-trigger-mw-sync to ensure that
	# the sync happens each time just before apache is started
	require mediawiki::packages

	exec { 	'mw-sync':
		command => "/usr/bin/sync-common",
		cwd => "/tmp",
		user => root,
		group => root,
		path => "/usr/bin:/usr/sbin",
		refreshonly => true,
		timeout => 60,
		logoutput => on_failure;
	}

}

class mediawiki::refreshlinks {
	# Include this to add cron jobs calling refreshLinks.php on all clusters. (RT-2355)

	define refreshlinks::cronjob() {

		$cluster = regsubst($name, '@.*', '\1')
		$hour = regsubst($name, '.*@', '\1')

		cron { "cron-refreshlinks-${name}":
			command => "/usr/local/bin/mwscriptwikiset refreshLinks.php ${cluster}.dblist --dfn-only",
			user => mwdeploy,
			hour => $hour,
			minute => 0,
			ensure => present,
		}
	}

	# add cron jobs - usage: <cluster>@<hour>
	refreshlinks::cronjob { ['s1@0','s2@2','s3@3','s4@4','s5@5','s6@6','s7@7']: }
}
