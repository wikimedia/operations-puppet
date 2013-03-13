# dependencies to run tools

class toollabs::run_environ {
	package { [
			'php5-cli',
			'php5-curl',
			'php5-mysql',
			'mono-runtime',
			'libhtml-parser-perl',
			'libwww-perl',
			'liburi-perl',
			'libdbd-sqlite3-perl',
			'ack-grep',
			'mysql-client-core-5.5',
			'python3',
			'python-twisted',
			'python-virtualenv',
			'python-mysqldb',
			'libmysqlclient-dev' ]:
		ensure => latest,
	}
}

