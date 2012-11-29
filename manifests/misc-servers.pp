# misc-servers.pp

# Resource definitions for miscellaneous servers

import "generic-definitions.pp"
import "nagios.pp"

class misc::noc-wikimedia {
	system_role { "misc::noc-wikimedia": description => "noc.wikimedia.org" }

	package { [ "apache2", "libapache2-mod-php5", "libapache2-mod-passenger", "libsinatra-ruby", "rails" ]:
		ensure => latest;
	}

	include passwords::ldap::wmf_cluster
	$proxypass = $passwords::ldap::wmf_cluster::proxypass

	file {
		"/etc/apache2/sites-available/noc.wikimedia.org":
			require => [ Apache_module[userdir], Apache_module[cgi], Package[libapache2-mod-php5] ],
			path => "/etc/apache2/sites-available/noc.wikimedia.org",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/noc.wikimedia.org";
		"/etc/apache2/sites-available/graphite.wikimedia.org":
			path => "/etc/apache2/sites-available/graphite.wikimedia.org",
			content => template('apache/sites/graphite.wikimedia.org'),
			mode => 0440,
			owner => root,
			group => www-data;
		"/usr/lib/cgi-bin":
			source => "puppet:///files/cgi-bin/noc/",
			recurse => true,
			ignore => ".svn",
			ensure => present;
	}

	apache_module { php5: name => "php5" }
	apache_module { userdir: name => "userdir" }
	apache_module { cgi: name => "cgi" }
	apache_module { ldap: name => "ldap" }
	apache_module { authnz_ldap: name => "authnz_ldap" }
	apache_module { proxy: name => "proxy" }
	apache_module { proxy_http: name => "proxy_http" }
	apache_module { ssl: name => "ssl" }

	apache_site { noc: name => "noc.wikimedia.org" }
	apache_site { graphiteproxy: name => "graphite.wikimedia.org" }

	service { apache2:
		require => [ Package[apache2], Apache_module[userdir], Apache_module[cgi], Apache_site[noc] ],
		subscribe => [ Package[libapache2-mod-php5], Apache_module[userdir], Apache_module[cgi], Apache_site[noc], File["/etc/apache2/sites-available/noc.wikimedia.org"] ],
		ensure => running;
	}

	# Monitoring
	monitor_service { "http": description => "HTTP", check_command => "check_http_url!noc.wikimedia.org!http://noc.wikimedia.org" }
}

class misc::images::rsyncd {
	system_role { "misc::images::rsyncd": description => "images rsync daemon" }

	class { 'generic::rsyncd': config => "export" }
}

class misc::images::rsync {
	system_role { "misc::images::rsync": description => "images rsync mirror host" }

	require misc::images::rsyncd

	$rsync_includes = "
- /upload/centralnotice/
- /upload/ext-dist/
+ /upload/wik*/
+ /private/
- **/thumb/
"

	file { "/etc/rsync.includes":
		content => $rsync_includes;
	}

	upstart_job { "rsync-images": install => "true" }
}

class misc::dc-cam-transcoder {
	system_role { "misc::dc-cam-transcoder": description => "Data center camera transcoder" }

	systemuser { video: name => "video", home => "/var/lib/video" }

	package { "vlc-nox":
		ensure => latest;
	}
}

class misc::survey {

# required packages and apache configs for limesurvey install

	system_role { "misc::survey": description => "limesurvey server" }

	require mysql::client
	package { [ "libapache2-mod-php5", "php5-cli", "php-pear", "php5-common", "php5-gd", "php5-mysql" ]:
		ensure => latest;
}

	file {
		# apche configs
		"/etc/apache2/sites-available/survey.wikimedia.org":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/survey.wikimedia.org";
	}

	apache_site { survey: name => "survey.wikimedia.org" }

	apache_module { ssl: name => "ssl" }
}

class misc::udpprofile::collector {
	system_role { "misc::udpprofile::collector": description => "MediaWiki UDP profile collector" }

	package { "udpprofile":
		ensure => latest;
	}

	service { udpprofile:
		require => Package[ 'udpprofile' ],
		ensure => running;
	}

	# Nagios monitoring (RT-2367)
	monitor_service { "carbon-cache": description => "carbon-cache.py", check_command => "nrpe_check_carbon_cache" }
	monitor_service { "profiler-to-carbon": description => "profiler-to-carbon", check_command => "nrpe_check_profiler_to_carbon" }
	monitor_service { "profiling collector": description => "profiling collector", check_command => "nrpe_check_profiling_collector" }

}

