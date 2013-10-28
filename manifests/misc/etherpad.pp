# Etherpad

class misc::etherpad {

	include passwords::etherpad
	$etherpad_admin_pass = $passwords::etherpad::etherpad_admin_pass
	$etherpad_sql_pass = $passwords::etherpad::etherpad_sql_pass

	system::role { "misc::etherpad": description => "Etherpad server" }

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

	include passwords::etherpad_lite

	$etherpad_db_user = $passwords::etherpad_lite::etherpad_db_user
	$etherpad_db_host = $passwords::etherpad_lite::etherpad_db_host
	$etherpad_db_name = $passwords::etherpad_lite::etherpad_db_name
	$etherpad_db_pass = $passwords::etherpad_lite::etherpad_db_pass

	if $realm == 'labs' {
		$etherpad_host = $fqdn
		$etherpad_ssl_cert = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
		$etherpad_ssl_key = '/etc/ssl/private/ssl-cert-snakeoil.key'
	} else {
		$etherpad_host = 'etherpad.wikimedia.org'
		$etherpad_serveraliases = 'epl.wikimedia.org'
		$etherpad_ssl_cert = '/etc/ssl/certs/star.wikimedia.org.pem'
		$etherpad_ssl_key = '/etc/ssl/private/star.wikimedia.org.key'
	}

	$etherpad_ip = '127.0.0.1'
	$etherpad_port = '9001'

	system::role { "misc::etherpad_lite": description => "Etherpad-lite server" }

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
	# FIX ME - move this to a common role to avoid duplicate defs
	# apache_module { rewrite: name => "rewrite" }
	apache_module { proxy: name => "proxy" }
	apache_module { proxy_http: name => "proxy_http" }
	# apache_module { ssl: name => "ssl" }

	package { etherpad-lite:
		ensure => latest;
	}
	service { etherpad-lite:
		require => Package["etherpad-lite"],
		subscribe => File['/etc/etherpad-lite/settings.json'],
		enable => true,
		ensure => running;
	}

	# Icinga process monitoring, RT #5790
	monitor_service { 'etherpad-lite-proc':
		description   => 'etherpad_lite_process_running',
		check_command => 'nrpe_check_etherpad_lite';
	}

	#FIXME
	#service { apache2:
	#	enable => true,
	#	ensure => running;
	#}

	file {
		'/etc/etherpad-lite/settings.json':
			require => Package[etherpad-lite],
			owner => 'root',
			group => 'root',
			mode => 0444,
			content => template('etherpad_lite/settings.json.erb');
	}
}

