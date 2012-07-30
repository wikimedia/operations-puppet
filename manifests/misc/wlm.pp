# Wiki Loves Monuments API server, RT#3221

class misc::wlm {
	system_role { "misc::wlm": description => "WLM API server" }

	include webserver::php5,
		webserver::php5-mysql,
		generic::apache::no-default-site

	class { "generic::mysql::server": version => "5.5" }

	file {
		"/etc/apache2/sites-available/wlm.wikimedia.org":
			mode => 0444,
			owner => root,
			group => root,
			notify => Service["apache2"],
			content => template('apache/sites/wlm.wikimedia.org.erb'),
			ensure => present;
	}

	apache_module { php5: name => "php5" }
	apache_site { wlm: name => "wlm.wikimedia.org" }


	file {
		# WLM checkouts and data
		"/var/wlm":
			owner => "root",
			ensure => directory,
			mode => 0777;
		# WLM API dir
		"/var/www/api":
			owner => root,
			ensure => directory;
		# Symlink to api.php
		"/var/www/api/api.php":
			owner => root,
			mode => 0444,
			ensure => symlink,
			target => "/var/wlm/erfgoed/api/api.php";
		# Update script
		"/var/wlm/update_from_toolserver.sh":
			owner => root,
			mode => 0555,
			ensure => present,
			source => "puppet:///files/wlm/update_from_toolserver.sh";
	}

	cron {
		update_from_toolserver:
			hour => 4, # TS updates on the 3rd hour
			command => "/var/wlm/update_from_toolserver.sh",
			user => "root";
	}
}
