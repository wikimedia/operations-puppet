# https://noc.wikimedia.org/

class misc::noc-wikimedia {
	system::role { "misc::noc-wikimedia": description => "noc.wikimedia.org" }

	include ::apache

	file {
		"/etc/apache2/sites-enabled/noc.wikimedia.org":
			require => [ Apache_module[userdir], Apache_module[cgi], Package[libapache2-mod-php5] ],
			path => "/etc/apache2/sites-enabled/noc.wikimedia.org",
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///files/apache/sites/noc.wikimedia.org";
	}

	# ensure default site is removed

	apache_module { php5: name => "php5" }
	apache_module { userdir: name => "userdir" }
	apache_module { cgi: name => "cgi" }
	apache_module { ssl: name => "ssl" }


	# Monitoring
	monitor_service { "http": description => "HTTP", check_command => "check_http_url!noc.wikimedia.org!http://noc.wikimedia.org" }

	# caches the ganglia xml data from gmetric used by dbtree every minute
	cron { dbtree_cache_cron:
		command => "/usr/bin/curl -s 'http://noc.wikimedia.org/dbtree/?recache=true' >/dev/null",
		user => www-data,
		minute => "*";
	}
}
