class misc::url-downloader {
	system_role { "misc::url-downloader": description => "Upload-by-URL proxy" }

	file { "/etc/squid/squid.conf":
		require => Package[squid],
		mode => 0444,
		owner => root,
		group => root,
		path => "/etc/squid/squid.conf",
		source => "puppet:///files/squid/copy-by-url-proxy.conf";
	}

	# pin package to the default, Ubuntu version, instead of our own
	apt::pin { [ 'squid', 'squid-common' ]:
		pin      => 'release o=Ubuntu',
		priority => '1001',
		before   => Package['squid'],
	}

	package { squid:
		ensure => latest;
	}

	service { squid:
		require => [ File["/etc/squid/squid.conf"], Package[squid], Interface_ip["misc::url-downloader"] ],
		subscribe => File["/etc/squid/squid.conf"],
		ensure => running;
	}
}
