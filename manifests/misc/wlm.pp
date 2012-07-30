# Wiki Loves Monuments API server, RT#3221

class misc::wlm {
	system_role { "misc::wlm": description => "Wiki Loves Monuments API" }

	include webserver::php5,
		webserver::php5-mysql,
		generic::apache::no-default-site

	if ( $::realm == "production" ) {
		include groups::wikidev
	}

	class { "generic::mysql::server": version => "5.5" }

	systemuser { wlm: name => "wlm", home => "/var/wlm", shell => "/bin/sh", groups => 'wikidev' }

	file {
		"/etc/apache2/sites-available/wlm.wikimedia.org":
			mode => 0444,
			owner => root,
			group => root,
			notify => Service["apache2"],
			source => "puppet:///files/apache/sites/wlm.wikimedia.org",
			ensure => present;
	}

	apache_site { wlm: name => "wlm.wikimedia.org" }

	file {
		# WLM checkouts and data
		"/var/wlm":
			owner => root,
			group => wikidev,
			ensure => directory,
			mode => 0775;
		# WLM API directories
		"/srv/org":
			owner => root,
			ensure => directory;
		"/srv/org/wikimedia":
			owner => root,
			ensure => directory;
		"/srv/org/wikimedia/wlm":
			owner => root,
			ensure => directory;
		# Symlink to api.php
		"/srv/org/wikimedia/wlm/api.php":
			owner => root,
			mode => 0555,
			ensure => symlink,
			target => "/var/wlm/erfgoed/api/api.php";
		# Update script
		"/usr/local/sbin/update_from_toolserver.sh":
			owner => root,
			mode => 0555,
			ensure => present,
			source => "puppet:///files/misc/wlm/update_from_toolserver.sh";
	}

	cron {
		"update_from_toolserver":
			require => [ File["/usr/local/sbin/update_from_toolserver.sh"], Systemuser["wlm"] ],
			hour => 4, # TS updates on the 3rd hour
			command => "/usr/local/sbin/update_from_toolserver.sh",
			user => "wlm";
	}
}
