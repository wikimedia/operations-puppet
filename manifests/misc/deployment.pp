# misc/deployment-host.pp

# deployment hosts

class misc::deployment {
	system_role { "misc::deployment": description => "Deployment host" }

	$wp = '/home/wikipedia'

	file {
		"/h"         : ensure => link, target =>  "/home";
		"/home/w"    : ensure => link, target =>  '/home/wikipedia';

		"${wp}/b"   : ensure => link, target =>  "${wp}/bin";
		"${wp}/c"   : ensure => link, target =>  "${wp}/common";
		"${wp}/d"   : ensure => link, target =>  "${wp}/doc";
		"${wp}/docs": ensure => link, target =>  "${wp}/doc";
		"${wp}/h"   : ensure => link, target =>  "${wp}/htdocs";
		"${wp}/l"   : ensure => link, target =>  "${wp}/logs";
		"${wp}/log" : ensure => link, target =>  "${wp}/logs";
		"${wp}/s"   : ensure => link, target =>  "${wp}/src";
	}
}

class misc::deployment::scripts {
	require passwordscripts

	# scap requires sync-common, which is in the wikimedia-task-appserver package
	require mediawiki_new

	# TODO: Should this be in a package instead, maybe? It's conceptually nicer than keeping scripts in the puppet git repo,
	# but rebuilding packages isn't as easy as updating a file through this mechanism, right?

	package { "php5-parsekit": ensure => present; }

	$scriptpath = "/usr/local/bin"

	file { $scriptpath:
		owner => root
		group => root,
		mode => 0555,
		recurse => remote,
		source => "puppet:///files/misc/deployment-scripts/bin/";
	}

	# Bug 37076
	Package['php5-parsekit'] -> File["${scriptpath}/lint"]
	Package['php5-parsekit'] -> File["${scriptpath}/lint.php"]

	file {
		"${scriptpath}/sync-apache-simulated":
			owner => root,
			group => root,
			mode => 0555,
			ensure => link,
			target => "${scriptpath}/sync-apache";
		"/usr/local/sbin/set-group-write2":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/set-group-write2";
	}
}

class misc::deployment::passwordscripts {
	include passwords::misc::scripts

	define passwordscript($scriptpath="/usr/local/bin") {
		$password = inline_template("scope.lookupvar(\"passwords::misc::scripts::${title}\")")
		
		file { "${scriptpath}/${title}":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => "#!/bin/bash\necho -n \"${password}\"\n"
		}
	}
	
	$passwords = [ 'cachemgr_pass', 'mysql_root_pass', 'nagios_sql_pass', 'webshop_pass', 'wikiadmin_pass',
		'wikiuser2_pass', 'wikiuser_pass', 'wikiuser_pass_nagios', 'wikiuser_pass_real' ]
	
	passwordscript { $passwords: }


class misc::deployment::l10nupdate {
	require misc::deployment::scripts

	$scriptpath = "/usr/local/bin"

	cron { 'l10nupdate':
		command => "${scriptpath}/l10nupdate-1 >> /var/log/l10nupdatelog/l10nupdate.log 2>&1",
		user => 'l10nupdate',
		hour => 2,
		minute => 0,
		ensure => present;
	}

	file {
		"${scriptpath}/l10nupdate":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/l10nupdate/l10nupdate";
		"${scriptpath}/l10nupdate-1":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/l10nupdate/l10nupdate-1";
		"${scriptpath}/sync-l10nupdate":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/l10nupdate/sync-l10nupdate";
		"${scriptpath}/sync-l10nupdate-1":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/l10nupdate/sync-l10nupdate-1";
	}

	# Make sure the log directory exists and has adequate permissions.
	# It's called l10nupdatelog because /var/log/l10nupdate was used
	# previously so it'll be an existing file on some systems.
	# Also create the dir for the SVN checkouts, and set up log rotation
	file {
		"/var/log/l10nupdatelog":
			owner => 'l10nupdate',
			group => 'wikidev',
			mode => 0664,
			ensure => directory;
		"/var/lib/l10nupdate":
			owner => 'l10nupdate',
			group => 'wikidev',
			mode => 0755,
			ensure => directory;
		"/etc/logrotate.d/l10nupdate":
			source => "puppet:///files/logrotate/l10nupdate",
			mode => 0444;
	}
}

