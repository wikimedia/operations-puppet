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

		$hour = regsubst(${name}, '^s', '\\1')

		cron { "cron-refreshlinks-${name}":
			command => "/usr/local/bin/mwscriptwikiset refreshLinks.php ${name}.dblist --dfn-only",
			user => root,
			hour => ${name},
			minute => 0,
			ensure => present,
		}
	}

	# simply going 'one per s[1-7] cluster and hour' here, so s1 runs at hour 1 and so on..
	refreshlinks::cronjob { ['s1','s2','s3','s4','s5','s6','s7']: }
}
