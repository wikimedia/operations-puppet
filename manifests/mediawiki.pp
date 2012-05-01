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
#
# Parameters:
# $branch = "",   optional
# $origin_url = "https://gerrit.wikimedia.org/r/p/test/mediawiki/core.git", optional.
#
# Usage:
# mediawiki::clone { "name_of_my_clone":
#   path   =>  '/path/to/mediawiki"
#   branch => 'crazy_branch',
# }
# # This will clone mediawiki core into /path/to/mediawiki/core
#
# TODO: add ensure parameter to ensure absent or present.
#       absent would delete the $path, ensure would clone.
#       Need to modify git::clone to do this.
# TODO: handle owner, group, and mode.
define mediawiki::clone (
	$path   = "/var/www/mediawiki",
	$branch = "",
	$origin_url = "https://gerrit.wikimedia.org/r/p/test/mediawiki/core.git") {

	git::clone { "mediawiki_${title}":
		directory => $path,
		branch    => $branch,
		origin    => $origin_url,
	}	
}