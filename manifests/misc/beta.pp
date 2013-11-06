class misc::beta::autoupdater {

	require misc::deployment::common_scripts

	# Parsoid JavaScript dependencies are updated on beta via npm
	package { 'npm':
		ensure => present,
	}

	file {
		# Old shell version
		"/usr/local/bin/wmf-beta-autoupdate":
			ensure => absent;
		# Python rewrite
		"/usr/local/bin/wmf-beta-autoupdate.py":
			owner => root,
			group => root,
			mode => 0555,
			require => [
				Package['git-core'],
			],
			source => 'puppet:///files/misc/beta/wmf-beta-autoupdate.py';
		"/etc/default/wmf-beta-autoupdate":
			ensure => absent;
		"/etc/init/wmf-beta-autoupdate.conf":
			ensure => absent;
	}

	# Make sure wmf-beta-autoupdate can run the l10n updater as l10nupdate
	sudo_user { "mwdeploy" : privileges => [
		'ALL = (l10nupdate) NOPASSWD:/usr/local/bin/mw-update-l10n',
		'ALL = (l10nupdate) NOPASSWD:/usr/local/bin/mwscript',
		# Some script running as mwdeploy explicily use "sudo -u mwdeploy"
		# which makes Ubuntu to request a password. The following rule
		# make sure we are not going to ask the password to mwdeploy when
		# it tries to identify as mwdeploy.
		'ALL = (mwdeploy) NOPASSWD: ALL',

		# mergeMessageFileList.php is run by mw-update-l10n as the apache user
		# since https://gerrit.wikimedia.org/r/#/c/44548/
		# Let it runs mwscript and others as apache user.
		'ALL = (apache) NOPASSWD: ALL',
	] }

	# Phase out old upstart job
	file { '/etc/init.d/wmf-beta-autoupdate':
		ensure => absent;
	}

}

class misc::beta::sync-site-resources {
	file { "/usr/local/bin/sync-site-resources":
		ensure => present,
		owner => root,
		group => root,
		mode => 0555,
		source => "puppet:///files/misc/beta/sync-site-resources"
	}

	cron { "sync-site-resources":
		command => "/usr/local/bin/sync-site-resources >/dev/null 2>&1",
		require => File["/usr/local/bin/sync-site-resources"],
		hour => 12,
		user => apache,
		ensure => present,
	}
}

