# dependencies to build tools

class toollabs::dev_environ {
	package { [	'mono-complete',
			'python-dev',
			'sqlite3',
			'autoconf',
			'libtool' ]:
		ensure => latest,
	}
}

