class exim::constants {
	$primary_mx = [ "208.80.152.186", "2620::860:2:219:b9ff:fedd:c027" ]
}

# this section from old exim.pp



class exim::packages {
	if ! $exim_install_type {
		$exim_install_type = 'light'
	}

	package { [ "exim4-config" ]:
		ensure => latest;
	}

	if ( $exim_install_type == 'light' ) {
		package { [ "exim4-daemon-light" ]:
			ensure => latest;
		}
	}
	if ( $exim_install_type == 'heavy' ) {
		package { [ "exim4-daemon-heavy" ]:
			ensure => latest;
		}
	}
}

class exim::config {

	if ! $exim_queuerunner {
		$exim_queuerunner = 'queueonly'
	}

	file {
		"/etc/default/exim4":
			owner => root,
			group => root,
			mode => 0444,
			content => template("exim/exim4.default.erb");
	}
}

class exim::service {

	if ( $exim_install_type == 'light' ) {
		service {
			"exim4":
				require => [ File["/etc/default/exim4"], File["/etc/exim4/exim4.conf"], Package[exim4-daemon-light] ],
				subscribe => [ File["/etc/default/exim4"], File["/etc/exim4/exim4.conf"] ],
				ensure => running;
		}
	}
	if ( $exim_install_type == 'heavy' ) {
		service {
			"exim4":
				require => [ File["/etc/default/exim4"], File["/etc/exim4/exim4.conf"], Package[exim4-daemon-heavy] ],
				subscribe => [ File["/etc/default/exim4"], File["/etc/exim4/exim4.conf"] ],
				ensure => running;
		}
	}
}

class exim::simple-mail-sender {
	$exim_queuerunner = 'queueonly'
	$exim_install_type = 'light'

	require exim::packages
	include exim::config
	include exim::service


	file {
		"/etc/exim4/exim4.conf":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/exim/exim4.minimal.conf";
	}
}

class exim::rt {
	$exim_queuerunner = 'combined'
	$exim_install_type = 'light'

	require exim::packages
	include exim::config
	include exim::service

	file {
		"/etc/exim4/exim4.conf":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/exim/exim4.rt.conf";
	}

	# Nagios monitoring
	monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
}

class exim::smtp {

	$otrs_mysql_password = $passwords::exim4::otrs_mysql_password
	$smtp_ldap_password = $passwords::exim4::smtp_ldap_password
}

class exim::roled($exim_enable_mail_relay="false", $exim_enable_mailman="false", $exim_enable_imap_delivery="false", $exim_enable_mail_submission="false", $exim_mediawiki_relay="false", $exim_enable_spamassassin="false" ) {

	$exim_install_type = 'heavy'
	$exim_queuerunner = 'combined'

	include exim::packages
	include exim::config
	include exim::service
	if ( $exim_enable_mailman == "true" ) {
		include mailman::listserve
	}
	if ( $exim_enable_spamassassin == "true" ) {
		include spamassassin
	}

	file {
		"/etc/exim4/exim4.conf":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///templates/exim/exim4.conf.exim4.conf.SMTP_IMAP_MM.erb";
	}
	if ( $exim_enable_mailman == "true" ) {
		file {
			"/etc/exim4/aliases/":
				require => Package[exim4-config],
				mode => 0755,
				owner => root,
				group => root,
				path => "/etc/exim4/aliases/",
				ensure => directory;
			"/etc/exim4/aliases/lists.wikimedia.org":
				require => [ File["/etc/exim4/aliases"], Package[exim4-config] ],
				owner => root,
				group => root,
				mode => 0444,
				source => "puppet:///files/exim/exim4.listserver_aliases.conf";
			"/etc/exim4/system_filter":
				require => Package[exim4-config],
				owner => root,
				group => root,
				mode => 0444,
				source => "puppet:///private/exim/exim4.listserver_system_filter.conf.listserve";
		}
	}
	if ( $exim_mail_relay == "primary" ) or ( $exim_mail_relay == "secondary" ) {
		file {
			"/etc/exim4/relay_domains":
				require => Package[exim4-config],
				owner => root,
				group => root,
				mode => 0444,
				source => "puppet:///files/exim/exim4.listserver_relay_domains.conf";
		}
	}

	# Nagios monitoring
	monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
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
			subscribe => [ File["/etc/default/spamassassin"], File["/etc/spamassassin/local.cf"],
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
