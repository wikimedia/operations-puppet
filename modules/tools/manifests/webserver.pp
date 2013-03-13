# tools-webserver-xx

class tools::webserver {
	require tools::run_environ
	require gridengine::submit_host

	package { [
			'apache2-mpm-prefork',
			'libapache2-mod-php5filter',
			'libapache2-mod-suphp']:
		ensure => latest,
	}
}

