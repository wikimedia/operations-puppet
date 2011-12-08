# mail.pp

class exim {
	class constants {
		$primary_mx = [ "208.80.152.186", "2620::860:2:219:b9ff:fedd:c027" ]
	}

	class config($install_type="light", $queuerunner="queueonly") {
		package { [ "exim4-config", "exim4-daemon-${install_type}" ]: ensure => latest }

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

	class roled($enable_mail_relay="false", $enable_mailman="false", $enable_imap_delivery="false", $enable_mail_submission="false", $mediawiki_relay="false", $enable_spamassassin="false" ) {
		class { "exim::config": install_type => "heavy", queuerunner => "combined" }
		Class["exim::config"] -> Class[exim::roled]

		include exim::service

		include exim::smtp
		include exim::constants
		include network::constants

		# TODO: check permissions of config files, these contain passwords
		file {
			"/etc/exim4/exim4.conf":
				require => Package[exim4-config],
				owner => root,
				group => root,
				mode => 0444,
				content => template("exim/exim4.conf.SMTP_IMAP_MM.erb");
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
				# TODO: check if this is only used for Mailman
				"/etc/exim4/system_filter":
					owner => root,
					group => root,
					mode => 0444,
					source => "puppet:///private/exim/exim4.listserver_system_filter.conf.listserve";
			}			
		}
		
		if ( $enable_mailman == "true" ) {
			include mailman, mailman::listserve
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

	file {
		"/etc/spamassassin/local.cf":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/spamassassin/local.cf";
		"/etc/default/spamassassin":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/spamassassin/spamassassin.default";
	}

	service { "spamassassin":
			require => [ File["/etc/default/spamassassin"], File["/etc/spamassassin/local.cf"], Package[spamassassin] ],
			subscribe => [ File["/etc/default/spamassassin"], File["/etc/spamassassin/local.cf"] ],
			ensure => running;
	}

	user { "spamd":
		ensure => present;
	}

	file { "/var/spamd":
		ensure => directory,
		owner => spamd,
		group => spamd,
		mode => 0700;
	}

	monitor_service { "spamd": description => "spamassassin", check_command => "check_procs_spamd" }
}

# basic mailman
class mailman::base {

	package { [ "mailman" ]:
		ensure => latest;
	}
	
	monitor_service { "procs_mailman": description => "mailman", check_command => "check_procs_mailman" }

}


# mailman for a list server
class mailman::listserve {

	require mailman::base
	require lighttpd::mailman

	file {
		"/etc/mailman/mm_cfg.py":
			require => Package[mailman],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/mailman/mm_cfg.py";

	}
}


# FIXME: put mailman specific config bits in conf.d/ directory files.
# move custom stuff to files in /etc/lighttpd/conf-available/
# use lighttpd_config to enable

# lighttpd setup as used by the mailman UI (lists.wm)
class lighttpd::mailman {

	require	generic::webserver::static

	# FIXME: still some custom stuff in global config
	file {
		"lighttpd.conf":
			mode => 0444,
			owner => root,
			group => root,
			path => "/etc/lighttpd/lighttpd.conf",
			source => "puppet:///files/lighttpd/list-server.conf";
		"mailman-private-archives.conf":
			mode => 0444,
			owner => root,
			group => root,
			path => "/etc/lighttpd/conf-available/mailman-private-archives.conf",
			source => "puppet:///files/lighttpd/mailman-private-archives.conf";
	}

	# shouldn't the generic class also have a source and ensure the file is in conf-available?
	# currently it is just for enabling it to conf-enabled
	lighttpd_config	{ "mailman-private-archives":
			name => "mailman-private-archives.conf";
	}

	# if we have this we dont need the lists. cert, right? we had them both before
	install_certificate{ "star.wikimedia.org": }

	# monitor SSL cert expiry 
	monitor_service { "https": description => "HTTPS", check_command => "check_ssl_cert!*.wikimedia.org" }
}
