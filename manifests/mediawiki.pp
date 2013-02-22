# mediawiki.pp

class mediawiki::packages {
	package { [ 'wikimedia-task-appserver', 'php5-redis', 'php5-memcached', 'libmemcached10', 'php5-igbinary' ]:
		ensure => latest;
	}

	# Disable timidity-daemon
	# It's recommended by timidity and there's no simple way to avoid installing it
	service { 'timidity':
		enable => false,
		ensure => stopped;
	}
}

class mediawiki::sync {
	# Include this for syncing mw installation
	# Include apache::apache-trigger-mw-sync to ensure that
	# the sync happens each time just before apache is started
	require mediawiki::packages

	exec { 'mw-sync':
		command => '/usr/bin/sync-common',
		cwd => '/tmp',
		user => root,
		group => root,
		path => '/usr/bin:/usr/sbin',
		refreshonly => true,
		timeout => 600,
		logoutput => on_failure;
	}

	# l10nupdate account required for syncing
	include accounts::l10nupdate

}

class mediawiki::refreshlinks {
	# Include this to add cron jobs calling refreshLinks.php on all clusters. (RT-2355)

	file { '/home/mwdeploy/refreshLinks':
		ensure => directory,
		owner => mwdeploy,
		group => mwdeploy,
		mode => 0664,
	}

	define refreshlinks::cronjob() {

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
	refreshlinks::cronjob { ['s2@2', 's3@3', 's4@4', 's5@5', 's6@6', 's7@7']: }
}

class mediawiki::user {
	systemuser { 'mwdeploy': name => 'mwdeploy' }
}

class mediawiki::former-extdist-removesoon {
	package { xinetd:
		ensure => absent;
	}

	systemuser { extdist: name => "extdist", home => "/var/lib/extdist", ensure => absent }

	file {
		"/etc/xinetd.d/svn_invoker":
			ensure => absent;
		"/etc/logrotate.d/svn-invoker":
			ensure => absent;
	}

	cron { extdist_updateall:
		ensure => absent;
	}
}

