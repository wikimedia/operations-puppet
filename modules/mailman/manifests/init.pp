class mailman {
	class base {
		# lighttpd needs to be installed first, or the mailman package will pull in apache2
		require webserver::static

		package { "mailman": ensure => latest }
	}

	class listserve {
		require mailman::base

		system_role { "mailman::listserve": description => "Mailman listserver" }

		file {
			"/etc/mailman/mm_cfg.py":
				owner => root,
				group => root,
				mode => 0444,
				source => "puppet:///modules/mailman/mm_cfg.py";
		}

		# Install as many languages as possible
		include generic::locales::international

		generic::debconf::set {
			"mailman/gate_news":
				value => "false",
				notify => Exec["dpkg-reconfigure mailman"];
			"mailman/used_languages":
				value => "ar big5 ca cs da de en es et eu fi fr gb hr hu ia it ja ko lt nl no pl pt pt_BR ro ru sl sr sv tr uk vi zh_CN zh_TW",
				notify => Exec["dpkg-reconfigure mailman"];
			"mailman/default_server_language":
				value => "en",
				notify => Exec["dpkg-reconfigure mailman"];
		}
		exec { "dpkg-reconfigure mailman":
			require => Class["generic::locales::international"],
			before => Service[mailman],
			command => "/usr/sbin/dpkg-reconfigure -fnoninteractive mailman",
			refreshonly => true
		}

		service { mailman:
			ensure => running,
			hasstatus => false,
			pattern => "mailmanctl"
		}

		monitor_service { "procs_mailman": description => "mailman", check_command => "nrpe_check_mailman" }
	}

	class web-ui {
		include webserver::static

		if ( $realm == "production" ) {
			install_certificate{ "star.wikimedia.org": }
		}

		# htdigest file for private list archives
		file { "/etc/lighttpd/htdigest":
			require => Class["webserver::static"],
			source => "puppet:///private/lighttpd/htdigest",
			owner => root,
			group => www-data,
			mode => 0440;
		}

		# Enable CGI module
		lighttpd_config { "10-cgi": require => Class["webserver::static"] }

		# Install Mailman specific Lighttpd config file
		lighttpd_config { "50-mailman":
			require => [ Class["webserver::static"], File["/etc/lighttpd/htdigest"] ],
			install => "true"
		}

		# Add files in /var/www (docroot)
		file { "/var/www":
			source => "puppet:///modules/mailman/docroot/",
			owner => root,
			group => root,
			mode => 0444,
			recurse => remote;
		}

		# monitor SSL cert expiry
		if ( $realm == "production" ) {
			monitor_service { "https": description => "HTTPS", check_command => "check_ssl_cert!*.wikimedia.org" }
		}
	}

	include listserve, web-ui
}
