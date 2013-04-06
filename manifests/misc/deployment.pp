# misc/deployment-host.pp

# deployment hosts

class misc::deployment {
	system_role { "misc::deployment": description => "Deployment host" }
	include misc::deployment::scap_primary,
		misc::dsh
}

# Scripts common to both git-deploy and scap
class misc::deployment::common_scripts {
	require passwordscripts

	# scap requires sync-common, which is in the wikimedia-task-appserver package
	require mediawiki

	# TODO: Should this be in a package instead, maybe? It's conceptually nicer than keeping scripts in the puppet git repo,
	# but rebuilding packages isn't as easy as updating a file through this mechanism, right?

	package { ["php5-parsekit", "libwww-perl", "libnet-dns-perl"]:
		 ensure => present;
	}

	$scriptpath = "/usr/local/bin"

	file {
		"${scriptpath}/clear-profile":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/clear-profile";
		"${scriptpath}/configchange":
			ensure => absent;
		"${scriptpath}/dologmsg":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/dologmsg";
		"${scriptpath}/deploy2graphite":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/deploy2graphite";
		"${scriptpath}/fatalmonitor":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/fatalmonitor";
		"${scriptpath}/foreachwiki":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/foreachwiki";
		"${scriptpath}/foreachwikiindblist":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/foreachwikiindblist";
		"${scriptpath}/lint":
			owner => root,
			group => root,
			mode => 0555,
			require => Package[ 'php5-parsekit' ], # bug 37076
			source => "puppet:///files/misc/scripts/lint";
		"${scriptpath}/lint.php":
			owner => root,
			group => root,
			mode => 0555,
			require => Package[ 'php5-parsekit' ], # bug 37076
			source => "puppet:///files/misc/scripts/lint.php";
		"${scriptpath}/mwscript":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/mwscript";
		"${scriptpath}/mwscriptwikiset":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/mwscriptwikiset";
		"${scriptpath}/mwversionsinuse":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/mwversionsinuse";
		"${scriptpath}/notifyNewProjects":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/notifyNewProjects";
		"${scriptpath}/purge-checkuser": # FIXME this is for a hume cronjob. Should puppetize the cronjob and move this to another class
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/purge-checkuser";
		"${scriptpath}/purge-varnish":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/purge-varnish";
		"${scriptpath}/refreshWikiversionsCDB":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/refreshWikiversionsCDB";
		"${scriptpath}/reset-mysql-slave":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/reset-mysql-slave";
		"${scriptpath}/set-group-write":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/set-group-write";
		"${scriptpath}/sql":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/sql";
		"${scriptpath}/sync-apache":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/sync-apache";
		"${scriptpath}/sync-apache-simulated":
			owner => root,
			group => root,
			mode => 0555,
			ensure => link,
			target => "${scriptpath}/sync-apache";
		"${scriptpath}/udprec":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/udprec";
		"/usr/local/sbin/set-group-write2":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/set-group-write2";
		"${scriptpath}/apache-fast-test":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/apache-fast-test";
		"${scriptPath}/updateinterwikicache":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/misc/scripts/updateinterwikicache";

		# Manpages
		# Need to be generated manually using make in files/misc/scripts
		"/usr/local/share/man/man1":
			ensure => 'directory',
			recurse => true,
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/misc/scripts/man";
	}
}

# Scripts for the new git-deploy deployment system
class misc::deployment::scripts {
	include misc::deployment::vars,
		misc::deployment::common_scripts
}

# Scripts for the old rsync-based deployment system
class misc::deployment::scap_scripts {
	include misc::deployment::common_scripts

	class { "misc::deployment::vars": system => "scap" }

	$scriptpath = "/usr/local/bin"

	file {
		"${scriptpath}/mw-update-l10n":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/scap/mw-update-l10n";
		"${scriptpath}/scap":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/scap/scap";
		"${scriptpath}/scap-1":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/scap/scap-1";
		"${scriptpath}/scap-2":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/scap/scap-2";
		"${scriptpath}/sync-common-all":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/scap/sync-common-all";
		"${scriptpath}/sync-common-file":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/scap/sync-common-file";
		"${scriptpath}/sync-dblist":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/scap/sync-dblist";
		"${scriptpath}/sync-dir":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/scap/sync-dir";
		"${scriptpath}/sync-docroot":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/scap/sync-docroot";
		"${scriptpath}/sync-file":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/scap/sync-file";
		"${scriptpath}/sync-wikiversions":
			owner => root,
			group => root,
			mode => 0555,
			source => "puppet:///files/scap/sync-wikiversions";
	}
}

class misc::deployment::passwordscripts {
	include passwords::misc::scripts
	$cachemgr_pass = $passwords::misc::scripts::cachemgr_pass
	$mysql_root_pass = $passwords::misc::scripts::mysql_root_pass
	$nagios_sql_pass = $passwords::misc::scripts::nagios_sql_pass
	$webshop_pass = $passwords::misc::scripts::webshop_pass
	$wikiadmin_pass = $passwords::misc::scripts::wikiadmin_pass
	$wikiuser2_pass = $passwords::misc::scripts::wikiuser2_pass
	$wikiuser_pass = $passwords::misc::scripts::wikiuser_pass
	$wikiuser_pass_nagios = $passwords::misc::scripts::wikiuser_pass_nagios
	$wikiuser_pass_real = $passwords::misc::scripts::wikiuser_pass_real

	$scriptpath = "/usr/local/bin"

	file {
		"${scriptpath}/cachemgr_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/cachemgr_pass.erb");
		"${scriptpath}/mysql_root_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/mysql_root_pass.erb");
		"${scriptpath}/nagios_sql_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/nagios_sql_pass.erb");
		"${scriptpath}/webshop_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/webshop_pass.erb");
		"${scriptpath}/wikiadmin_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/wikiadmin_pass.erb");
		"${scriptpath}/wikiuser2_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/wikiuser2_pass.erb");
		"${scriptpath}/wikiuser_pass":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/wikiuser_pass.erb");
		"${scriptpath}/wikiuser_pass_nagios":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/wikiuser_pass_nagios.erb");
		"${scriptpath}/wikiuser_pass_real":
			owner => root,
			group => wikidev,
			mode => 0550,
			content => template("misc/passwordScripts/wikiuser_pass_real.erb");
	}
}

class misc::deployment::l10nupdate {
	require misc::deployment::scap_scripts

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

class misc::deployment::vars ($system = "git-deploy") {
	if $system == "git-deploy" {
		$mw_common = "/srv/deployment/mediawiki/common"
		$mw_common_source = $mw_common
		$dblist_common = "/srv/deployment/mediawiki/common/dblists"
		$dblist_common_source = $dblist_common
	} elsif $system == "scap" {
		$mw_common = "/usr/local/apache/common-local"
		$mw_common_source = "/a/common"
		$dblist_common = $mw_common
		$dblist_common_source = $mw_common_source
	}
	file {
		"/usr/local/lib/mw-deployment-vars.sh":
			owner => root,
			group => root,
			mode => 0444,
			content => template("misc/mw-deployment-vars.erb");
	}
}

class misc::deployment::scap_primary {
	class { 'generic::rsyncd': config => "scap-primary" }
}

class misc::deployment::scap_proxy {
	class { 'generic::rsyncd': config => "scap" }
}
