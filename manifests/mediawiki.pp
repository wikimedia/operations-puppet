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

	file { "/home/mwdeploy/refreshLinks":
		ensure => directory,
		owner => mwdeploy,
		group => mwdeploy,
		mode => 0664,
	}

	define refreshlinks::cronjob() {

		$cluster = regsubst($name, '@.*', '\1')
		$hour = regsubst($name, '.*@', '\1')

		cron { "cron-refreshlinks-${name}":
			command => "/usr/local/bin/mwscriptwikiset refreshLinks.php ${cluster}.dblist --dfn-only > /home/mwdeploy/refreshLinks/${name}.log 2>&1",
			user => mwdeploy,
			hour => $hour,
			minute => 0,
			ensure => present,
		}
	}

	# add cron jobs - usage: <cluster>@<hour>
	refreshlinks::cronjob { ['s1@0']: }
}

# Define: mediawiki::clone
# Uses git::clone to clone a working copy of Mediawiki core.
#
# Parameters:
#	$directory	-	path to clone the repository into.  Required.
#	$origin		- 	Origin repository URL.  Default: "https://gerrit.wikimedia.org/r/p/test/mediawiki/core.git"
#	$branch		-	Branch you would like to check out.
#	$ensure		-   'absent', 'present', or 'latest'.  Defaults to 'present'.  
#					'latest' will execute a git pull if there are any changes.
#					'absent' will ensure the directory is deleted.
# Usage:
#	mediawiki_clone { "name_of_my_clone": directory =>  '/path/to/mediawiki/core" }
#	# This will clone mediawiki core into /path/to/mediawiki/core and checkout crazy_branch.
#
# TODO: handle owner, group, and mode (recursively?).
define mediawiki::clone (
	$directory  = "/var/www/mediawiki/core",
	$origin     = "https://gerrit.wikimedia.org/r/p/test/mediawiki/core.git",
	$branch     = "",
	$ensure     = 'present') {

	git::clone { "mediawiki_${title}":
		directory => $directory,
		branch    => $branch,
		origin    => $origin_url,
		ensure    => 'present',
	}
}