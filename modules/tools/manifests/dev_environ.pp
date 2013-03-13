# dependencies to build tools

class tools::dev_environ {
	package { [
			'sqlite3',
			'autoconf',
			'libtool' ]:
		ensure => latest,
	}
}

