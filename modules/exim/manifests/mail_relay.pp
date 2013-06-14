class exim::mail_relay {
	Class["exim::config"] -> Class[exim::mail_relay]

	file {
		"/etc/exim4/relay_domains":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///modules/exim/exim4.secondary_relay_domains.conf";
	}
}
