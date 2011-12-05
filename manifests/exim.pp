# exim.pp

class exim::packages {
	package { [ "exim4-daemon-light", "exim4-config" ]:
		ensure => latest;
	}

	# FIXME: the name "exim::packages" suggests that this
	# class only installs the packages. Why does it also
	# install configuration?
	if ! $exim_queuerunner {
		$exim_queuerunner = 'queueonly'
	}

	# FIXME: indentation
	file {
	"/etc/default/exim4":
		owner => root,
		group => root,
		mode => 0444,
		content => template("exim/exim4.default.erb");
	}
}

class exim::packages::heavy {
	# FIXME: Should this be a class parameter perhaps?
	$exim_queuerunner = 'combined'

	package { [ "exim4-daemon-heavy", "exim4-config" ]:
		ensure => latest;
}

	# FIXME: This is a duplicate of exim::packages. Break out
	# into a separate class so it exists only once.
	# FIXME: indentation
	file {
	"/etc/default/exim4":
		owner => root,
		group => root,
		mode => 0444,
		content => template("exim/exim4.default.erb");
	}
}

class exim::service {
	# FIXME: indentation
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
			mode => 0444,
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
			mode => 0444,
			source => "puppet:///files/exim/exim4.rt.conf";
	}

	include exim::service

	# Nagios monitoring
	monitor_service { "smtp": description => "Exim SMTP", check_command => "check_smtp" }
}

class exim::listserve {

	# FIXME: How is the mailman specific Exim configuration handled?
	# Does exim::packages::heavy take care of that? Isn't it misnamed
	# in that case?
	# TODO: Create one, generic exim configuration file template, which is shared
	# by mchenry (mail relay), sodium (lists server, backup mail) and sanger
	# (IMAP), with variables/parameters to customize its contents. Can use include
	# files as well.
	include exim::packages::heavy

	file {

		## conf for exim
		# TODO: Might want to make this a puppet list instead of a fixed file
		"/etc/exim4/relay_domains":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/exim/exim4.listserver_relay_domains.conf";
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
		# TODO: Make a generic template as well
		"/etc/exim4/system_filter":
			require => Package[exim4-config],
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///private/exim/exim4.listserver_system_filter.conf";
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

	# FIXME: Doesn't this depend on everything else being done first?
	service { "spamassassin":
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

	monitor_service { "spamd": description => "spamassassin", check_command => "check_procs_generic!1!20!1!40!spamd" }
}
