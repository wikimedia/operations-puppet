# misc-servers.pp

# Resource definitions for miscellaneous servers

import "generic-definitions.pp"
import "nagios.pp"

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

