# RT - Request Tracker
class misc::rt::server {
	system_role { "misc::rt::server": description => "RT server" }

	package { [ "request-tracker3.8", "rt3.8-db-mysql", "rt3.8-clients", "libcgi-fast-perl", "lighttpd" ]:
		ensure => latest;
	}

	$rtconf = "# This file is for the command-line client, /usr/bin/rt.\n\nserver http://localhost/rt\n"

	file {
		"/etc/lighttpd/conf-available/10-rt.conf":
			source => "puppet:///files/rt/10-rt.lighttpd.conf";
		"/var/run/fastcgi":
			ensure => directory,
			owner => "www-data",
			group => "www-data",
			mode => 0750;
		"/etc/request-tracker3.8/RT_SiteConfig.d/50-debconf":
			source => "puppet:///files/rt/50-debconf",
			notify => Exec["update-rt-siteconfig"];
		"/etc/request-tracker3.8/RT_SiteConfig.d/80-wikimedia":
			source => "puppet:///files/rt/80-wikimedia",
			notify => Exec["update-rt-siteconfig"];
		"/etc/request-tracker3.8/RT_SiteConfig.pm":
			owner => "root",
			group => "www-data",
			mode => 0440;
		"/etc/request-tracker3.8/rt.conf":
			require => Package["request-tracker3.8"],
			content => $rtconf;
		"/etc/cron.d/mkdir-var-run-fastcgi":
			content => "@reboot	root	mkdir /var/run/fastcgi";
	}

	exec { "update-rt-siteconfig":
		command => "update-rt-siteconfig-3.8",
		path => "/usr/sbin",
		refreshonly => true;
	}

	lighttpd_config { "10-rt":
		require => [ Package["request-tracker3.8"], File["/etc/lighttpd/conf-available/10-rt.conf"] ],
	}

	service { lighttpd:
		ensure => running;
	}
}

