class exim::mailman {
	Class["exim::config"] -> Class[exim::mailman]

	file {
		"/etc/exim4/aliases/lists.wikimedia.org":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///modules/exim/exim4.listserver_aliases.conf";
	}
}
