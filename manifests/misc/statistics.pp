# this file is for stat[0-9]/(ex-bayes) statistics servers (per ezachte - RT 2162)

class misc::statistics::user {
	$username = "stats"
	systemuser { "$username":
		name   => "$username",
		home   => "/var/lib/$username",
		groups => "wikidev",
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
		"/mnt/data":
			ensure => directory;
	}

	# need this for NFS mounts.
	include nfs::common

	# Mount /data from dataset2 server.
	# xmldumps and other misc files needed
	# for generating statistics are here.
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

	include webserver::apache	
	webserver::apache::module { "rewrite": require => Class["webserver::apache"] }
	webserver::apache::site { $site_name: 
		require => [Class["webserver::apache"], Webserver::Apache::Module["rewrite"]],
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

# Class: misc::statistics::gerrit_stats
#
# Installs diederik's gerrit-stats python
# scripts, and sets up cron jobs to run them.
class misc::statistics::gerrit_stats {
	$gerrit_stats_repo_url = "https://gerrit.wikimedia.org/r/p/analytics/gerrit-stats.git"
	$gerrit_stats_path     = "/a/gerrit-stats"

	# This user need to have access to gerrit
	# from the node on which this class
	# is included.  We'll use diederik for now.
	$gerrit_stats_user     = "stats"
	
	file { $gerrit_stats_path:
		owner  => $gerrit_stats_user,
		group  => "wikidev",
		mode   => 0775,
		ensure => "directory",
	}

	# Clone the gerrit-stats repository
	# into a subdir of $gerrit_stats_path.
	# This requires that the $gerrit_stats_user
	# has an ssh key that is allowed to clone
	# from git.less.ly.
	git::clone { "gerrit-stats":
		directory => "$gerrit_stats_path/gerrit-stats",
		origin    => $gerrit_stats_repo_url,
		owner     => $gerrit_stats_user,
		require   => User[$gerrit_stats_user],
		ensure    => "latest",
	}

	# run a cron job from the $gerrit_stats_path.
	# This will create a $gerrit_stats_path/data
	# directory containing stats about gerrit.
	cron { "gerrit-stats-daily":
		command => "cd $gerrit_stats_path && /usr/bin/python $gerrit_stats_path/gerrit-stats/gerritstats/stats.py",
		user    => $gerrit_stats_user,
		hour    => '23',
		minute  => '59',
		require => Git::Clone["gerrit-stats"],
	}
}
