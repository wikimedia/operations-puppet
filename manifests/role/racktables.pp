# https://racktables.wikimedia.org
class misc::racktables {
	# When this class is chosen, ensure that apache, php5-common, php5-mysql are
	# installed on the host via another package set.

	system_role { "misc::racktables": description => "Racktables" }

	if $realm == "labs" {
		$racktables_host = "$instancename.${domain}"
		$racktables_ssl_cert = "/etc/ssl/certs/star.wmflabs.pem"
		$racktables_ssl_key = "/etc/ssl/private/star.wmflabs.key"
	} else {
		$racktables_host = "racktables.wikimedia.org"
		$racktables_ssl_cert = "/etc/ssl/certs/star.wikimedia.org.pem"
		$racktables_ssl_key = "/etc/ssl/private/star.wikimedia.org.key"
		install_certificate{ 'star.wikimedia.org': }
	}

	class {'webserver::php5': ssl => 'true'; }

	include generic::mysql::packages::client,
		webserver::php5-gd,
		passwords::racktables

	file {
		"/etc/apache2/sites-available/racktables.wikimedia.org":
		mode => 0444,
		owner => root,
		group => root,
		notify => Service["apache2"],
		content => template('apache/sites/racktables.wikimedia.org.erb'),
		ensure => present;
	}

	file {
		"/srv/org/wikimedia/racktables/inc/secret.php":
		mode => 444,
		owner => root,
		group => root,
		content => template('racktables/racktables.config.erb'),
		ensure => present;
	}

	apache_site { racktables: name => "racktables.wikimedia.org" }
	apache_confd { namevirtualhost: install => "true", name => "namevirtualhost" }
	apache_module { rewrite: name => "rewrite" }
}
