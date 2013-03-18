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

	include misc::statistics::packages

	file {
		"/a":
			owner => root,
			group => wikidev,
			mode => 0775,
			ensure => directory,
			recurse => "false";
	}

	# Manually set a list of statistics servers.
	# 208.80.152.146 - stat1
	# 208.80.154.155 - stat1001
	$servers = ["stat1.wikimedia.org", "stat1001.wikimedia.org", "analytics1027.eqiad.wmnet"]

	# set up rsync modules for copying files
	# on statistic servers in /a
	class { "misc::statistics::rsyncd": hosts_allow => $servers }
}


class misc::statistics::packages {
	package { ["mc", "zip", "p7zip", "p7zip-full", "subversion", "mercurial", "tofrodos"]:
		ensure => latest;
	}

	include misc::statistics::packages::python
}

# Packages needed for various python stuffs
# on statistics servers.
class misc::statistics::packages::python {
	package { [
		"libapache2-mod-python",
		"python-django",
		"python-mysqldb",
		"python-yaml",
		"python-dateutil",
		"python-numpy",
		"python-scipy",
	]:
		ensure => 'installed',
	}
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
	require mediawiki::users::mwdeploy

	$statistics_mediawiki_directory = "/a/mediawiki/core"

	git::clone { "statistics_mediawiki":
		directory => $statistics_mediawiki_directory,
		origin    => "https://gerrit.wikimedia.org/r/p/mediawiki/core.git",
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
			"r-cran-rmysql",
			"libcairo2",
			"libcairo2-dev",
			"libxt-dev"
		]:
		ensure => installed;
	}
}


class misc::statistics::webserver {
	include webserver::apache

	# make sure /var/log/apache2 is readable by wikidevs for debugging.
	# This won't make the actual log files readable, only the directory.
	# Individual log files can be created and made readable by
	# classes that manage individual sites.
	file { "/var/log/apache2":
		ensure  => "directory",
		owner   => "root",
		group   => "wikidev",
		mode    => 0750,
		require => Class["webserver::apache"],
	}
}

# stats.wikimedia.org
class misc::statistics::sites::stats {
	$site_name = "stats.wikimedia.org"
	$docroot = "/srv/$site_name/htdocs"

	# add htpasswd file for stats.wikimedia.org
	file { "/etc/apache2/htpasswd.stats":
		owner   => "root",
		group   => "root",
		mode    => 0644,
		source  => "puppet:///private/apache/htpasswd.stats",
	}

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

# community-analytics.wikimedia.org
class misc::statistics::sites::community_analytics {
	$site_name = "community-analytics.wikimedia.org"
	$docroot = "/srv/org.wikimedia.community-analytics/community-analytics/web_interface"

	# org.wikimedia.community-analytics is kinda big,
	# it really lives on /a.
	# Symlink /srv/a/org.wikimedia.community-analytics to it.
	file { "/srv/org.wikimedia.community-analytics":
		ensure => "/a/srv/org.wikimedia.community-analytics"
	}

	webserver::apache::site { $site_name:
		require => [Class["webserver::apache"], Class["misc::statistics::packages::python"]],
		docroot => $docroot,
		server_admin => "noc@wikimedia.org",
		custom => [
			"SetEnv MPLCONFIGDIR /srv/org.wikimedia.community-analytics/mplconfigdir",

	"<Location \"/\">
		SetHandler python-program
		PythonHandler django.core.handlers.modpython
		SetEnv DJANGO_SETTINGS_MODULE web_interface.settings
		PythonOption django.root /community-analytics/web_interface
		PythonDebug On
		PythonPath \"['/srv/org.wikimedia.community-analytics/community-analytics'] + sys.path\"
	</Location>",

	"<Location \"/media\">
		SetHandler None
	</Location>",

	"<Location \"/static\">
		SetHandler None
	</Location>",

	"<LocationMatch \"\\.(jpg|gif|png)$\">
		SetHandler None
	</LocationMatch>",
	],
	}
}

# metrics-api.wikimedia.org
# See: http://stat1.wikimedia.org/rfaulk/pydocs/_build/env.html
# for more info on how and why.
class misc::statistics::sites::metrics {
	require passwords::mysql::research,
		passwords::mysql::research_prod,
		passwords::mysql::metrics
	$site_name        = "metrics.wikimedia.org"
	$document_root    = "/srv/org.wikimedia.metrics"

	$e3_home          = "/a/e3"
	$e3_analysis_path = "$e3_home/E3Analysis"
	$e3_user          = $misc::statistics::user::username

	# connetions will be rendered into settings.py.
	$mysql_connections = {
		'slave'   => {
			'user'   =>  $passwords::mysql::metrics::user,
			'passwd' =>  $passwords::mysql::metrics::pass,
			'host'   =>  'db1047.eqiad.wmnet',
			'port'   =>  3306,
			'db'     =>  'prod',
		},
		'cohorts' =>  {
			'user'   =>  $passwords::mysql::research_prod::user,
			'passwd' =>  $passwords::mysql::research_prod::pass,
			'host'   =>  'db1047.eqiad.wmnet',
			'port'   =>  3306,
			'db'     =>  'prod',
		},
		's1'      =>  {
			'user'   =>   $passwords::mysql::research::user,
			'passwd' =>   $passwords::mysql::research::pass,
			'host'   =>  's1-analytics-slave.eqiad.wmnet',
			'port'   =>   3306,
		},
		's2'      =>  {
			'user'   =>   $passwords::mysql::research::user,
			'passwd' =>   $passwords::mysql::research::pass,
			'host'   =>  's2-analytics-slave.eqiad.wmnet',
			'port'   =>  3306,
		},
		's3'      =>  {
			'user'   =>   $passwords::mysql::research::user,
			'passwd' =>   $passwords::mysql::research::pass,
			'host'   =>  's3-analytics-slave.eqiad.wmnet',
			'port'   =>  3306,
		},
		's4'      =>  {
			'user'   =>   $passwords::mysql::research::user,
			'passwd' =>   $passwords::mysql::research::pass,
			'host'   =>  's4-analytics-slave.eqiad.wmnet',
			'port'   =>  3306,
		},
		's5'      =>  {
			'user'   =>   $passwords::mysql::research::user,
			'passwd' =>   $passwords::mysql::research::pass,
			'host'   =>  's5-analytics-slave.eqiad.wmnet',
			'port'   =>  3306,
		},
	}

	package { "python-flask":
		ensure => "installed",
	}

	file { [$e3_home, $document_root]:
		ensure => "directory",
		owner  => $misc::statistics::user::username,
		group  => "wikidev",
		mode   => 0775,
	}

	# install a .htpasswd file for E3
	file { "$e3_home/.htpasswd":
		content  => 'e3:$apr1$krR9Lhez$Yr0Ya9GpCW8KRQLeyR5Rn.',
		owner    => $e3_user,
		group    => "wikidev",
		mode     => 0664,
	}

	# clone the E3 Analysis repository
	git::clone { "E3Analysis":
		directory => "$e3_analysis_path",
		origin    => "https://gerrit.wikimedia.org/r/p/analytics/E3Analysis.git",
		owner     => $e3_user,
		require   => [Package["python-flask"], File[$e3_home], Class["misc::statistics::user"], Class["misc::statistics::packages::python"]],
		ensure    => "latest",
	}

	# Need settings.py to configure metrics-api python application
	# Make this only readable by stats user; it has db passwords in it.
	file { "$e3_analysis_path/user_metrics/config/settings.py":
		content => template("misc/e3-metrics.settings.py.erb"),
		owner   => $e3_user,
		group   => "root",
		mode    => 0640,
		require => Git::Clone["E3Analysis"],
	}

	# symlink the api.wsgi app loader python script.
	# api.wsgi loads 'src.api' as a module :/
	file { "$document_root/api.wsgi":
		ensure  => "$e3_analysis_path/user_metrics/api/api.wsgi",
		require => Git::Clone["E3Analysis"],
	}

	include webserver::apache
	# Set up the Python WSGI VirtualHost
	webserver::apache::module { "wsgi": }
	webserver::apache::module { "alias": }
	webserver::apache::site { $site_name:
		require      => [File["/srv/org.wikimedia.metrics"], File["$e3_home/.htpasswd"], Class["webserver::apache"], Webserver::Apache::Module["wsgi"], Webserver::Apache::Module['alias']],
		server_admin => "noc@wikimedia.org",
		docroot      => $document_root,
		access_log   => "/var/log/apache2/access.metrics.log",
		error_log    => "/var/log/apache2/error.metrics.log",
		custom       => ["
    WSGIDaemonProcess api user=$e3_user group=wikidev threads=5 python-path=$e3_analysis_path
    WSGIScriptAlias / $document_root/api.wsgi

    <Directory $document_root>
        WSGIProcessGroup api
        WSGIApplicationGroup %{GLOBAL}
        Order deny,allow
        Allow from all
    </Directory>",
"
    <Location />
        Order deny,allow
        AuthType Basic
        AuthName \"WMF E3 Metrics API\"
        AuthUserFile $e3_home/.htpasswd
        require valid-user
        Deny from all
        Satisfy any
    </Location>",
	],
	}

	# This site used to be named metrics-api.
	# Set up a VirtualHost to handle redirects.
	file { "/etc/apache2/sites-enabled/metrics-api.wikimedia.org":
		content => "
# Redirect metrics-api.wikimedia.org to $site_name.
<VirtualHost *:80>
    ServerName metrics-api.wikimedia.org
    Redirect permanent / http://$site_name
</VirtualHost>
",
	}

	# make access and error log for metrics-api readable by wikidev group
	file { ["/var/log/apache2/access.metrics.log", "/var/log/apache2/error.metrics.log"]:
		group   => "wikidev",
		require => Webserver::Apache::Site[$site_name],
	}
}



# installs a generic mysql server
# for loading and manipulating sql dumps.
class misc::statistics::db::mysql {
	# install a mysql server with the
	# datadir at /a/mysql
	class { "generic::mysql::server":
		datadir => "/a/mysql",
		version => "5.5",
	}
}

# installs MonogDB on stat1
class misc::statistics::db::mongo {
	class { "mongodb":
		dbpath => "/a/mongodb",
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



	# Clone the gerrit-stats and gerrit-stats/data
	# repositories into subdirs of $gerrit_stats_path.
	# This requires that the $gerrit_stats_user
	# has an ssh key that is allowed to clone
	# from git.less.ly.

	git::clone { "gerrit-stats":
		directory => "$gerrit_stats_path",
		origin    => $gerrit_stats_repo_url,
		owner     => $gerrit_stats_user,
		require   => [User[$gerrit_stats_user], Class["misc::statistics::packages::python"]],
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
		command => "/usr/bin/python $gerrit_stats_path/gerritstats/stats.py --dataset $gerrit_stats_data_path --toolkit dygraphs --settings /a/gerrit-stats/gerrit-stats/gerritstats/settings.yaml >> $gerrit_stats_base/gerrit-stats.log && (cd $gerrit_stats_data_path && git add . && git commit -q -m \"Updating gerrit-stats data after gerrit-stats run at $(date)\" && git push -q)",
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
#
# Parameters:
#   hosts_allow - array.  Hosts to grant rsync access.
class misc::statistics::rsyncd($hosts_allow = undef) {
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
		hosts_allow => $hosts_allow,
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
	file { ["/a/squid", "/a/squid/archive", "/a/aft", "/a/aft/archive", "/a/eventlogging"]:
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

	# edit logs from locke
	misc::statistics::rsync_job { "edits":
		source      => "locke.wikimedia.org::udp2log/archive/edits*.gz",
		destination => "/a/squid/archive/edits",
	}

	# eventlogging logs from vanadium
	misc::statistics::rsync_job { "eventlogging":
		source      => "vanadium.eqiad.wmnet::eventlogging/archive/*.gz",
		destination => "/a/eventlogging/archive",
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
		owner   => "$misc::statistics::user::username",
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


# Class: misc::statistics::cron_blog_pageviews
#
# Sets up daily cron jobs to run a script which
# groups blog pageviews by url and emails them
class misc::statistics::cron_blog_pageviews {
	$script = "/usr/local/bin/blog.sh"

	file {
		"$script":
			mode    => 0755,
			content => template("misc/email-blog-pageviews.erb");
	}

	# Create a daily cron job to run the blog script
	# This requires that the $misc::statistics::user::username
	# user is installed on the source host.
	cron { "rsync_${name}_logs":
		command => "$script",
		user    => "$misc::statistics::user::username",
		hour    => 8,
		minute  => 0,
	}
}
