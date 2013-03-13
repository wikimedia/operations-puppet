# dependencies to run tools

class tools::run_environ {
	package { [
			'php5-cli',
			'libhtml-parser-perl',
			'libwww-perl',
			'liburi-perl',
			'libdbd-sqlite3-perl',
			'ack-grep',
			'mysql-client-core-5.5',
			'python-twisted',
			'python-virtualenv',
			'python-pip',
			'python-dev',
			'python-mysqldb',
			'libmysqlclient-dev' ]:
		ensure => latest,
	}

	package { 'oursql':
		ensure => latest,
		provider => pip,
		require => Package['python-pip', 'python-dev', 'python-mysqldb', 'libmysqlclient-dev'],
	}

	package { 'requests':
		ensure => latest,
		provider => pip,
		require => Package['python-pip', 'python-dev', 'python-mysqldb', 'libmysqlclient-dev'],
	}
}

