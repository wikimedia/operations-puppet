# Etherpad

class misc::etherpad {

	include passwords::etherpad
	$etherpad_admin_pass = $passwords::etherpad::etherpad_admin_pass
	$etherpad_sql_pass = $passwords::etherpad::etherpad_sql_pass

	system_role { "misc::etherpad": description => "Etherpad server" }

	require webserver::modproxy

	# NB: this has some GUI going on all up in it. first install must be done by hand.
	package { etherpad:
		ensure => latest;
	}

	service { etherpad:
		require => Package[etherpad],
		ensure => running;
	}

	file {
		"/etc/init.d/etherpad":
			source => "puppet:///files/misc/etherpad/etherpad.init",
			mode => 0555,
			owner => root,
			group => root;
		"/etc/apache2/sites-available/etherpad.proxy":
			source => "puppet:///files/misc/etherpad/etherpad.proxy.apache.conf",
			mode => 0444,
			owner => root,
			group => root;
		"/etc/etherpad/etherpad.local.properties":
			content => template("etherpad/etherpad.local.properties.erb"),
			mode => 0444,
			owner => root,
			group => root;
	}

	apache_module { proxy: name => "proxy" }
	apache_site { etherpad_proxy: name => "etherpad.proxy" }

	# Nagios monitoring
	monitor_service { "etherpad http":
		description => "Etherpad HTTP",
		check_command => "check_http_on_port!9000";
	}

}

class misc::etherpad_lite {

	include webserver::apache2,
		passwords::etherpad_lite

	$etherpad_db_pass = $passwords::etherpad_lite::etherpad_db_pass

	if $realm == "labs" {
		$etherpad_host = $fqdn
		$etherpad_ssl_cert = "/etc/ssl/certs/ssl-cert-snakeoil.pem"
		$etherpad_ssl_key = "/etc/ssl/private/ssl-cert-snakeoil.key"
	}

	system_role { "misc::etherpad_lite": description => "Etherpad-lite server" }

	file {
		"/etc/apache2/sites-available/etherpad.wikimedia.org":
			mode => 0444,
			owner => root,
			group => root,
			notify => Service["apache2"],
			content => template('apache/sites/etherpad_lite.wikimedia.org.erb'),
			ensure => present;
	}

	apache_site { controller: name => "etherpad.wikimedia.org" }
	apache_module { rewrite: name => "rewrite" }
	apache_module { proxy: name => "proxy" }
	apache_module { proxy_http: name => "proxy_http" }
	apache_module { ssl: name => "ssl" }

	package { etherpad-lite:
		ensure => latest;
	}
	service { etherpad-lite:
		require => Package["etherpad-lite"],
		subscribe => File['/etc/etherpad-lite/settings.json'],
		enable => true,
		ensure => running;
	}
	service { apache2:
		enable => true,
		ensure => running;
	}

	file {
		'/etc/etherpad-lite/settings.json':
			require => Package[etherpad-lite],
			owner => 'root',
			group => 'root',
			mode => 0444,
			content => template('etherpad_lite/settings.json.erb');
		'/etc/apache2/sites-enabled/000-default':
			notify => Service["apache2"],
			require => Package["apache2"],
			ensure => absent;
	}
}

