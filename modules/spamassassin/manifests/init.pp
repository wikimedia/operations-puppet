class spamassassin {
	include network::constants

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
			content => template("spamassassin/local.cf");
		"/etc/default/spamassassin":
			source => "puppet:///modules/spamassassin/spamassassin.default";
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

	monitor_service { "spamd": description => "spamassassin", check_command => "nrpe_check_spamd" }
}
