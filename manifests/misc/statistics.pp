# this file is for stat[0-9]/(ex-bayes) statistics servers (per ezachte - RT 2162)

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
	
	# Mount /data from dataset2 server.
	# xmldumps and other misc files needed
	# for generating statistics are here.
	mount { "/mnt/data":
		device => "208.80.152.185:/data",
		fstype => "nfs",
		options => "ro,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr,addr=208.80.152.185",
		atboot => true,
		require => File['/mnt/data'],
		ensure => mounted,
	}
}

# clones mediawiki core at /a/mediawiki/core
# and sets up a cron job to pull once a day.
# RT 2162
class misc::statistics::mediwiki {
	$statistics_mediawiki_directory = "/a/mediawiki"
	
	file { $statistics_mediawiki_directory:
			owner   => root,
			group   => wikidev,
			mode    => 0775,
			ensure  => directory,
			recurse => "false";
	}

	# clone mediawiki core to /a/mediawiki
	mediawiki::clone { "statistics": 
		path    => $statistics_mediawiki_directory,
		require => File[$statistics_mediawiki_directory],
	}
	
	# group wikidev and 775 the clone
	$clone_directory = "$statistics_mediawiki_directory/core"
	file { $clone_directory: 
		owner  => 'root',
		group  => wikidev,
		mode   => 0664, #  directories will automatically be +x by puppet with recurse
		ensure => directory,
		recurse => true,
		require => Mediawiki::Clone["statistics"],
	}

	# set up a cron to pull mediawiki clone once a day
	cron { "git-pull-${statistics_mediawiki_directory}/core":
		hour => 0,
		minute => 0,
		command => "cd ${statistics_mediawiki_directory}/core && /usr/bin/git pull",
		require => Mediawiki::Clone["statistics"],
	}
}

# RT 2164
class misc::statistics::geoip {

	file {
		"/usr/local/share/GeoIP":
			owner => root,
			group => wikidev,
			mode => 0770,
			ensure => directory;
		"/usr/local/bin/geoiplogtag":
			owner => root,
			group => wikidev,
			mode => 0750,
			source => "puppet:///files/misc/geoiplogtag",
			ensure => present;
		"/usr/local/bin/update-maxmind-geoip-lib":
			owner => root,
			group => wikidev,
			mode => 0750,
			source => "puppet:///files/misc/update-maxmind-geoip-lib",
			ensure => present;
	}

	cron {
		"update-maxmind-geoip-lib":
			ensure => present,
			user => ezachte,
			command => "/usr/local/bin/update-maxmind-geoip-lib",
			monthday => 1,
			require => File['/usr/local/bin/update-maxmind-geoip-lib'];
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

	"<Directory \"$docroot/wikipedia.org/wikistats\">
		Options Indexes         
		AllowOverride None
		Order allow,deny
		Allow from all
	</Directory>",

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
