# this file is for stat[0-9]/(ex-bayes) statistics servers (per ezachte - RT 2162)

class misc::statistics::user {
	$username = "stats"
	$homedir  = "/var/lib/$username"

	systemuser { "$username":
		name   => "$username",
		home   => "$homedir",
		groups => "wikidev",
		shell  => "/bin/bash",
	}

	# create a .gitconfig file for stats user
	file { "$homedir/.gitconfig":
		mode    => 0664,
		owner   => $username,
		content => "[user]\n\temail = otto@wikimedia.org\n\tname = Statistics User",
	}
}

class misc::statistics::base {
	system_role { "misc::statistics::base": description => "statistics server" }

	$stat_packages = [ "mc", "zip", "p7zip", "p7zip-full", "subversion" ]

	package { $stat_packages:
		ensure => latest;
	}

	file {
		"/a":
			owner => root,
			group => wikidev,
			mode => 0775,
			ensure => directory,
			recurse => "false";
	}

	# set up rsync modules for copying files
	# on statistic servers in /a
	include misc::statistics::rsyncd
}

# Mounts /data from dataset2 server.
# xmldumps and other misc files needed
# for generating statistics are here.
class misc::statistics::dataset_mount {	
	# need this for NFS mounts.
	include nfs::common

	file { "/mnt/data": ensure => directory }

	mount { "/mnt/data":
		device => "208.80.152.185:/data",
		fstype => "nfs",
		options => "ro,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr,addr=208.80.152.185",
		atboot => true,
		require => [File['/mnt/data'], Class["nfs::common"]],
		ensure => mounted,
	}
}

# clones mediawiki core at /a/mediawiki/core
# and ensures that it is at the latest revision.
# RT 2162
class misc::statistics::mediawiki {
	require mediawiki::user

	$statistics_mediawiki_directory = "/a/mediawiki/core"

	git::clone { "statistics_mediawiki":
		directory => $statistics_mediawiki_directory,
		origin    => "https://gerrit.wikimedia.org/r/p/test/mediawiki/core.git",
		ensure    => 'latest',
		owner     => 'mwdeploy',
		group     => 'wikidev',
	}
}

# RT-2163
class misc::statistics::plotting {

	package { [ 
			"ploticus",
			"libploticus0",
			"r-base",
			"libcairo",
			"libcairo-dev",
			"libxt-dev"
		]:
		ensure => installed;
	}
}

# stats.wikimedia.org
class misc::statistics::site {
	$site_name = "stats.wikimedia.org"
	$docroot = "/srv/$site_name/htdocs"

	# add htpasswd file for stats.wikimedia.org
	file { "/etc/apache2/htpasswd.stats":
		owner   => "root",
		group   => "root",
		mode    => 0644,
		source  => "puppet:///private/apache/htpasswd.stats",
	}

	include webserver::apache	
	webserver::apache::module { "rewrite": require => Class["webserver::apache"] }
	webserver::apache::site { $site_name: 
		require => [Class["webserver::apache"], Webserver::Apache::Module["rewrite"], File["/etc/apache2/htpasswd.stats"]],
		docroot => $docroot,
		aliases   => ["stats.wikipedia.org"],
		custom => [
			"Alias /extended $docroot/reportcard/extended",
			"Alias /staff $docroot/reportcard/staff \n",
			"RewriteEngine On",

	# redirect stats.wikipedia.org to stats.wikimedia.org
	"RewriteCond %{HTTP_HOST} stats.wikipedia.org
	RewriteRule ^(.*)$ http://$site_name\$1 [R=301,L]\n",

	# Set up htpasswd authorization for some sensitive stuff
	"<Directory \"$docroot/reportcard/staff\">
		AllowOverride None              
		Order allow,deny
		Allow from all
		AuthName \"Password protected area\"
		AuthType Basic
		AuthUserFile /etc/apache2/htpasswd.stats
		Require user wmf
	</Directory>",
	"<Directory \"$docroot/reportcard/extended\">
		AllowOverride None              
		Order allow,deny
		Allow from all
		AuthName \"Password protected area\"
		AuthType Basic
		AuthUserFile /etc/apache2/htpasswd.stats
		Require user internal
	</Directory>",
	"<Directory \"$docroot/reportcard/pediapress\">
		AllowOverride None              
		Order allow,deny
		Allow from all
		AuthName \"Password protected area\"
		AuthType Basic
		AuthUserFile /etc/apache2/htpasswd.stats
		Require user pediapress
	</Directory>",
	],
	}
}


# installs a generic mysql server
# for loading and manipulating sql dumps.
class misc::statistics::db {
	# install a mysql server with the
	# datadir at /a/mysql
	class { "generic::mysql::server":
		datadir => "/a/mysql",
		version => "5.5",
	}
}

# == Class misc::statistics::gerrit_stats
#
# Installs diederik's gerrit-stats python
# scripts, and sets a cron job to run it and
# to commit and push generated data into
# a repository.
#
class misc::statistics::gerrit_stats {
	$gerrit_stats_repo_url      = "https://gerrit.wikimedia.org/r/p/analytics/gerrit-stats.git"
	$gerrit_stats_data_repo_url = "ssh://stats@gerrit.wikimedia.org:29418/analytics/gerrit-stats/data.git"
	$gerrit_stats_base          = "/a/gerrit-stats"
	$gerrit_stats_path          = "$gerrit_stats_base/gerrit-stats"
	$gerrit_stats_data_path     = "$gerrit_stats_base/data"


	# use the stats user
	$gerrit_stats_user          = $misc::statistics::user::username
	$gerrit_stats_user_home     = $misc::statistics::user::homedir
	
	file { $gerrit_stats_base:
		owner  => $gerrit_stats_user,
		group  => "wikidev",
		mode   => 0775,
		ensure => "directory",
	}

	# gerrit-stats requires this packages
	package { "python-mysqldb": ensure => "installed" }

	# We also need pyyaml aka python-yaml.  
	# (This will also install libyaml as a dependency.)
	package { "python-yaml": ensure => "installed" }

	# Clone the gerrit-stats and gerrit-stats/data
	# repositories into subdirs of $gerrit_stats_path.
	# This requires that the $gerrit_stats_user
	# has an ssh key that is allowed to clone
	# from git.less.ly.

	git::clone { "gerrit-stats":
		directory => "$gerrit_stats_path",
		origin    => $gerrit_stats_repo_url,
		owner     => $gerrit_stats_user,
		require   => [User[$gerrit_stats_user], Package["python-mysqldb"], Package["python-yaml"]],
		ensure    => "latest",
	}

	git::clone { "gerrit-stats/data":
		directory => "$gerrit_stats_data_path",
		origin    => $gerrit_stats_data_repo_url,
		owner     => $gerrit_stats_user,
		require   => User[$gerrit_stats_user],
		ensure    => "latest",
	}

	# Make sure ~/.my.cnf is only readable by stats user.
	# The gerrit stats script requires this file to
	# connect to gerrit MySQL database.
	file { "$gerrit_stats_user_home/.my.cnf":
		mode  => 0600,
		owner => stats,
		group => stats,
	}

	# Run a cron job from the $gerrit_stats_path.
	# This will create a $gerrit_stats_path/data
	# directory containing stats about gerrit.
	#
	# Note: gerrit-stats requires mysql access to
	# the gerrit stats database.  The mysql user creds
	# are configured in /home/$gerrit_stats_user/.my.cnf,
	# which is not puppetized in order to keep pw private.
	#
	# Once gerrit-stats has run, the newly generated
	# data in $gerrit_stats_path/data will be commited
	# and pushed to the gerrit-stats/data repository.
	cron { "gerrit-stats-daily":
		command => "/usr/bin/python $gerrit_stats_path/gerritstats/stats.py --dataset $gerrit_stats_data_path --toolkit dygraphs | tee -a $gerrit_stats_base/gerrit-stats.log && (cd $gerrit_stats_data_path && git add . && git commit -m \"Updating gerrit-stats data after gerrit-stats run at $(date)\" && git push)",
		user    => $gerrit_stats_user,
		hour    => '23',
		minute  => '59',
		require => [Git::Clone["gerrit-stats"], Git::Clone["gerrit-stats/data"], File["$gerrit_stats_user_home/.my.cnf"]],
	}
}


# Sets up rsyncd and common modules
# for statistic servers.  Currently
# this is read/write between statistic
# servers in /a.
class misc::statistics::rsyncd {
	# this uses modules/rsync to
	# set up an rsync daemon service
	include rsync::server

	# set up an rsync module
	# (in /etc/rsync.conf) for /a
	rsync::server::module { "a": 
		path        => "/a",
		read_only   => "no",
		list        => "yes",
		# allow only statistics servers (stat1, stat1001)
		hosts_allow => $role::statistics::servers,
	}
}



# Class: misc::statistics::rsync::jobs
#
# Sets up daily cron jobs to rsync log files from remote
# logging hosts to a local destination for further processing.
class misc::statistics::rsync::jobs {

	# Make sure destination directories exist.
	# Too bad I can't do this with recurse => true.
	# See: https://projects.puppetlabs.com/issues/86
	# for a much too long discussion on why I can't.
	file { ["/a/squid", "/a/squid/archive", "/a/aft", "/a/aft/archive"]:
		ensure  => "directory",
		owner   => "stats",
		group   => "wikidev",
		mode    => 0775,
	}

	# wikipedia zero logs from oxygen
	misc::statistics::rsync_job { "wikipedia_zero":
		source      => "oxygen.wikimedia.org::udp2log/archive/zero-*.gz",
		destination => "/a/squid/archive/zero",
	}

	# teahouse logs from emery
	misc::statistics::rsync_job { "teahouse":
		source      => "emery.wikimedia.org::udp2log/archive/teahouse*.gz",
		destination => "/a/squid/archive/teahouse",
	}

	# arabic banner logs from emery
	misc::statistics::rsync_job { "arabic_banner":
		source      => "emery.wikimedia.org::udp2log/archive/arabic-banner*.gz",
		destination => "/a/squid/archive/arabic-banner",
	}

	# sampled-1000 logs from emery
	misc::statistics::rsync_job { "sampled_1000":
		source      => "emery.wikimedia.org::udp2log/archive/sampled-1000*.gz",
		destination => "/a/squid/archive/sampled",
	}

	# AFT clicktracking logs
	misc::statistics::rsync_job { "clicktracking":
		source      => "emery.wikimedia.org::udp2log/aft/archive/clicktracking*.gz",
		destination => "/a/aft/archive/clicktracking",
	}
}


# Define: misc::statistics::rsync_job
#
# Sets up a daily cron job to rsync from $source to $destination
# as the $misc::statistics::user::username user.  This requires
# that the $misc::statistics::user::username user is installed
# on both $source and $destination hosts.
#
# Parameters:
#    source      - rsync source argument (including hostname)
#    destination - rsync destination argument
#
define misc::statistics::rsync_job($source, $destination) {
	require misc::statistics::user

	# ensure that the destination directory exists
	file { "$destination":
		ensure  => "directory",
		owner   => "stats",
		group   => "wikidev",
		mode    => 0775,
	}

	# Create a daily cron job to rsync $source to $destination.
	# This requires that the $misc::statistics::user::username
	# user is installed on the source host.
	cron { "rsync_${name}_logs":
		command => "/usr/bin/rsync -rt $source $destination/",
		user    => "$misc::statistics::user::username",
		hour    => 8,
		minute  => 0,
	}
}
