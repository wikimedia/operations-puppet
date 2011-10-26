# exim.pp

class exim::packages {
	package { [ "exim4-daemon-light", "exim4-config" ]:
		ensure => latest;
	}

	if ! $exim_queuerunner {
		$exim_queuerunner = 'queueonly'
	}

	file {
	"/etc/default/exim4":
		owner => root,
		group => root,
		mode => 0644,
		content => template("exim/exim4.default.erb");
	}
}

class exim::packages::heavy {

	$exim_queuerunner = 'combined'

	package { [ "exim4-daemon-heavy", "exim4-config" ]:
		ensure => latest;
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

	service {
	"exim4":
		require => [ File["/etc/default/exim4"], File["/etc/exim4/exim4.conf"], Package[exim4-daemon-light] ],
		subscribe => [ File["/etc/default/exim4"], File["/etc/exim4/exim4.conf"] ],
		ensure => running;
	}
}

class exim::simple-mail-sender {
	$exim_queuerunner = 'queueonly'

	require exim::packages

	file {
		"/etc/exim4/exim4.conf":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0644,
			source => "puppet:///files/exim/exim4.minimal.conf";
	}

	include exim::service
}

class exim::rt {
	$exim_queuerunner = 'combined'

	require exim::packages

	file {
		"/etc/exim4/exim4.conf":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0644,
			source => "puppet:///files/exim/exim4.rt.conf";
	}

	include exim::service

	# Nagios monitoring
	monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
}

class exim::listserve {

	include exim::packages::heavy

	file {

		## conf for exim
		"/etc/exim4/relay_domains":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/exim/exim4.listserver_relay_domains.conf";
		"/etc/exim4/aliases/":
			require => Package[exim4-config],
			mode => 755,
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
			source => "puppet:///private/exim/exim4.listserver_system_filter.conf";
	}
}


# SpamAssassin http://spamassassin.apache.org/

class spamassassin {

	package { [ "spamassassin" ]:
		ensure => latest;
        }

	file { "/etc/spamassassin/local.cf":
		owner => root,
		group => root,
		mode => 0444,
		source => "puppet:///files/spamassassin/local.cf";
	}

	service { "spamassassin":
	require => Package[spamassassin],
	ensure => running;
	}

	monitor_service { "spamd": description => "spamassassin processes", check_command => "check_procs_spamd" }
}
