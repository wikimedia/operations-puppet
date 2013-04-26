class apt {
	# Directory to hold the repository signing keys
	file { '/var/lib/apt/keys':
		ensure  => directory,
		owner   => root,
		group   => root,
		mode    => '0700',
		recurse => true,
		purge   => true,
	}

	package { 'apt-show-versions':
		ensure => installed,
	}

	package { 'python-apt':
		ensure => installed,
	}

	file { '/usr/local/bin/apt2xml':
		ensure  => present,
		owner   => root,
		group   => root,
		mode    => '0755',
		source  => 'puppet:///modules/apt/apt2xml.py',
		require => Package['python-apt'],
	}

	apt::repository { 'wikimedia':
		uri         => 'http://apt.wikimedia.org/wikimedia',
		dist        => "${::lsbdistcodename}-wikimedia",
		components  => 'main universe',
		comment_old => true,
	}

	# prefer Wikimedia APT repository packages in all cases
	apt::pin { 'wikimedia':
		package  => '*',
		pin      => 'release o=Wikimedia',
		priority => 1001,
	}

	apt::conf { 'wikimedia-proxy':
		priority => '80',
		key      => 'Acquire::http::Proxy',
		value    => 'http://brewster.wikimedia.org:8080',
		ensure   => $::site ? {
			pmtpa       => present,
			eqiad       => present,
			default     => absent
		}
	}
}
