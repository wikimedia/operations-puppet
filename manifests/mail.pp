# mail.pp

class exim {
	class constants {
		$primary_mx = [ "208.80.152.186", "2620::860:2:219:b9ff:fedd:c027" ]
	}

	class config($install_type="light", $queuerunner="queueonly") {
		package { [ "exim4-config", "exim4-daemon-${install_type}" ]: ensure => latest }

		if $install_type == "heavy" {
			exec { "mkdir /var/spool/exim4/scan":
				require => Package[exim4-daemon-heavy],
				path => "/bin:/usr/bin",
				creates => "/var/spool/exim4/scan"
			}
			
			mount { [ "/var/spool/exim4/scan", "/var/spool/exim4/db" ]:
				device => "none",
				fstype => "tmpfs",
				options => "defaults",
				ensure => mounted
			}
			
			file { [ "/var/spool/exim4/scan", "/var/spool/exim4/db" ]:
				ensure => directory,
				owner => Debian-exim,
				group => Debian-exim
			}

			Exec["mkdir /var/spool/exim4/scan"] -> Mount["/var/spool/exim4/scan"] -> File["/var/spool/exim4/scan"]
			Package[exim4-daemon-heavy] -> Mount["/var/spool/exim4/db"] -> File["/var/spool/exim4/db"]
		}

		file {
			"/etc/default/exim4":
				require => Package[exim4-config],
				owner => root,
				group => root,
				mode => 0444,
				content => template("exim/exim4.default.erb");
			"/etc/exim4/aliases/":
				require => Package[exim4-config],
				mode => 0755,
				owner => root,
				group => root,
				ensure => directory;
		}
	}

	class service {
		Class["exim::config"] -> Class[exim::service]

		# The init script's status command exit value only reflects the SMTP service
		service { exim4:
			ensure => running,
			hasstatus => $exim::config::queuerunner ? {
				"queueonly" => false,
				default => true
			}
		}

		if $exim::config::queuerunner != "queueonly" {
			# Nagios monitoring
			monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
		}
	}

	class simple-mail-sender {
		class { "exim::config": queuerunner => "queueonly" }
		Class["exim::config"] -> Class[exim::simple-mail-sender]

		file {
			"/etc/exim4/exim4.conf":
				require => Package[exim4-config],
				owner => root,
				group => root,
				mode => 0444,
				source => "puppet:///files/exim/exim4.minimal.conf";
		}

		include exim::service
	}

	class rt {
		class { "exim::config": queuerunner => "combined" }
		Class["exim::config"] -> Class[exim::rt]

		file {
			"/etc/exim4/exim4.conf":
				require => Package[exim4-config],
				owner => root,
				group => root,
				mode => 0444,
				source => "puppet:///files/exim/exim4.rt.conf";
		}

		include exim::service
	}

	class smtp {
		$otrs_mysql_password = $passwords::exim4::otrs_mysql_password
		$smtp_ldap_password = $passwords::exim4::smtp_ldap_password
	}

	# TODO: add class documentation
	class roled($local_domains = [ "+system_domains" ], $enable_mail_relay="false", $enable_mailman="false", $enable_imap_delivery="false", $enable_mail_submission="false", $mediawiki_relay="false", $enable_spamassassin="false", $outbound_ips=[ $ipaddress ] ) {
		class { "exim::config": install_type => "heavy", queuerunner => "combined" }
		Class["exim::config"] -> Class[exim::roled]

		include exim::service

		include exim::smtp
		include exim::constants
		include network::constants
		include exim::listserve::private

		file {
			"/etc/exim4/exim4.conf":
				require => Package[exim4-config],
				owner => root,
				group => Debian-exim,
				mode => 0440,
				content => template("exim/exim4.conf.SMTP_IMAP_MM.erb");
			"/etc/exim4/system_filter":
				owner => root,
				group => Debian-exim,
				mode => 0444,
				content => template("exim/system_filter.conf.erb");
		}

		class mail_relay {
			Class["exim::config"] -> Class[exim::roled::mail_relay]

			file {
				"/etc/exim4/relay_domains":
					owner => root,
					group => root,
					mode => 0444,
					source => "puppet:///files/exim/exim4.listserver_relay_domains.conf";
			}
		}

		class mailman {
			Class["exim::config"] -> Class[exim::roled::mailman]
			
			file {
				"/etc/exim4/aliases/lists.wikimedia.org":
					owner => root,
					group => root,
					mode => 0444,
					source => "puppet:///files/exim/exim4.listserver_aliases.conf";
			}
		}
		
		if ( $enable_mailman == "true" ) {
			include mailman
		}
		if ( $enable_mail_relay == "primary" ) or ( $enable_mail_relay == "secondary" ) {
			include mail_relay
		}
		if ( $enable_spamassassin == "true" ) {
			include spamassassin
		}
	}
}

# SpamAssassin http://spamassassin.apache.org/

class spamassassin {

	package { [ "spamassassin" ]:
		ensure => latest;
	}

	systemuser { "spamd": name => "spamd" }

	File {
		require => Package[spamassassin],
		owner => root,
		group => root,
		mode => 0444
	}
	file {
		"/etc/spamassassin/local.cf":
			source => "puppet:///files/spamassassin/local.cf";
		"/etc/default/spamassassin":
			source => "puppet:///files/spamassassin/spamassassin.default";
	}

	service { "spamassassin":
			require => [ File["/etc/default/spamassassin"], File["/etc/spamassassin/local.cf"], Package[spamassassin], Systemuser[spamd] ],
			subscribe => [ File["/etc/default/spamassassin"], File["/etc/spamassassin/local.cf"] ],
			ensure => running;
	}

	file { "/var/spamd":
		require => Systemuser[spamd],
		ensure => directory,
		owner => spamd,
		group => spamd,
		mode => 0700;
	}

	monitor_service { "spamd": description => "spamassassin", check_command => "check_procs_generic!1!20!1!40!spamd" }
}

class mailman {
	class base {
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
				source => "puppet:///files/mailman/mm_cfg.py";
		}

		service { mailman:
			ensure => running,
			hasstatus => false,
			pattern => "mailmanctl"
		}

		monitor_service { "procs_mailman": description => "mailman", check_command => "check_procs_generic!1!25!1!35!mailman" }
	}

	class web-ui {
		# if we have this we dont need the lists. cert, right? we had them both before
		install_certificate{ "star.wikimedia.org": }

		lighttpd_config { "50-mailman":
			require => Class[Generic::webserver::static],
			install => true
		}

		# monitor SSL cert expiry 
		monitor_service { "https": description => "HTTPS", check_command => "check_ssl_cert!*.wikimedia.org" }
	}

	include listserve, web-ui
}
