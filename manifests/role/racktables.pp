# https://racktables.wikimedia.org

## Please note that Racktables is a tarball extraction based installation
## into its web directory root.  This means that puppet cannot fully automate
## the installation at this time & the actual tarball must be downloaded from
## http://racktables.org/ and unzipped into /srv/org/wikimedia/racktables

class role::racktables {
  system_role { 'role::racktables': description => 'Racktables' }

  # dependencies
	Class['webserver::php5'] -> apache_module['rewrite'] -> Install_certificate['star.wikimedia.org']


	#variables
	$racktables_host = 'racktables.wikimedia.org'
	$racktables_ssl_cert = '/etc/ssl/certs/star.wikimedia.org.pem'
	$racktables_ssl_key = '/etc/ssl/private/star.wikimedia.org.key'
	$racktables_db_host = 'db9.pmtpa.wmnet'
	$rackeables_db = 'racktables'
	install_certificate{ 'star.wikimedia.org': }

	class {'webserver::php5': ssl => true; }

	include generic::mysql::packages::client,
		webserver::php5-gd,
		passwords::racktables

	file {
		'/etc/apache2/sites-available/racktables.wikimedia.org':
		ensure  => present,
		mode    => '0444',
		owner   => 'root',
		group   => 'root',
		notify  => Service['apache2'],
		content => template('apache/sites/racktables.wikimedia.org.erb');
	}

	file {
		'/srv/org/wikimedia/racktables/wwwroot/inc/secret.php':
		ensure  => present,
		mode    => '0444',
		owner   => 'root',
		group   => 'root',
		content => template('racktables/racktables.config.erb');
	}

	apache_site { 'racktables': name => 'racktables.wikimedia.org' }
	apache_confd { 'namevirtualhost': install => true, name => namevirtualhost }
	apache_module { 'rewrite': name => rewrite }
}
