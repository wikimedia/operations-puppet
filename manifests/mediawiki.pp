# mediawiki.pp

class mediawiki::packages {
	package { 'wikimedia-task-appserver':
		ensure => latest;
	}
}

class mediawiki::sync {
	# Include this for syncinc mw installation
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
		timeout => 60,
		logoutput => on_failure;
	}

}

class mediawiki::cron::refreshlinks {
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

class mediawiki::user {
	systemuser { 'mwdeploy': name => 'mwdeploy' }
}

class mediawiki::user::l10nupdate {
	$authorized_key = 'command="uptime; touch /var/tmp/pybal-check.stamp" ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAzcA/wB0uoU+XgiYN/scGczrAGuN99O8L7m8TviqxgX9s+RexhPtn8FHss1GKi8oxVO1V+ssABVb2q0fGza4wqrHOlZadcFEGjQhZ4IIfUwKUo78mKhQsUyTd5RYMR0KlcjB4UyWSDX5tFHK6FE7/tySNTX7Tihau7KZ9R0Ax//KySCG0skKyI1BK4Ufb82S8wohrktBO6W7lag0O2urh9dKI0gM8EuP666DGnaNBFzycKLPqLaURCeCdB6IiogLHiR21dyeHIIAN0zD6SUyTGH2ZNlZkX05hcFUEWcsWE49+Ve/rdfu1wWTDnourH/Xm3IBkhVGqskB+yp3Jkz2D3Q== l10nupdate@fenari'

	require groups::l10nupdate

	systemuser { 'l10nupdate': name => 'l10nupdate', home => '/home/l10nupdate', default_group => 10002 }

	file {
		"/home/l10nupdate/.ssh":
			require => Systemuser["l10nupdate"],
			owner => l10nupdate,
			group => l10nupdate,
			mode => 0700,
			ensure => directory;
		"/home/l10nupdate/.ssh/authorized_keys":
			require => File["/home/l10nupdate/.ssh"],
			owner => l10nupdate,
			group => l10nupdate,
			mode => 0600,
			content => $authorized_key;
	}
}

# is installed on pdf servers - https://launchpad.net/ubuntu/+source/mediawiki-math
class mediawiki::math {
	package { 'mediawiki-math':
		ensure => latest;
	}
}
