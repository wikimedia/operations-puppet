# = Class: wikimania_scholarships
#
# This class installs/configures/manages the Wikimania Scholarships
# application.
#
# == Parameters:
# - $hostname: hostname for apache vhost
# - $deploy_dir: directory application is deployed to
# - $logs_dir: directory to write log files to
# - $serveradmin: administrative contact email address
# - $mysql_host: mysql database server
# - $mysql_db: mysql database
#
# == Sample usage:
#
#   class { "wikimania_scholarships": }
#
class wikimania_scholarships(
	$hostname = 'scholarships.wikimedia.org',
	$deploy_dir = '/srv/deployment/scholarships/scholarships',
	$logs_dir = '/var/log/scholarships',
	$serveradmin = 'root@wikimedia.org',
	$mysql_host = 'localhost',
	$mysql_db = 'scholarships'
){

	system::role { 'wikimania_scholarships':
		description => "${hostname}"
	}

	include passwords::mysql::wikimania_scholarship, webserver::php5-mysql

	$mysql_user = $passwords::mysql::wikimania_scholarships::user
	$mysql_pass = $passwords::mysql::wikimania_scholarships::password

	# Trebuchet deployment
	deployment::target { 'scholarships': }

	file {
		"/etc/apache2/sites-available/${hostname}":
			ensure  => present,
			mode    => '0444',
			owner   => 'root',
			group   => 'root',
			notify  => Service['apache2'],
			content => template('wikimania_scholarships/apache.conf.erb');

		'/etc/logrotate.d/wikimania_scholarships':
			ensure  => file,
			owner   => root,
			group   => root,
			mode    => '0444',
			content => template('wikimania_scholarships/logrotate.erb');

		"${deploy_dir}":
			ensure  => directory;

		"${deploy_dir}/.env":
			ensure  => present,
			mode    => '0444',
			owner   => 'root',
			group   => 'root',
			notify  => Service['apache2'],
			content => template('wikimania_scholarships/env.erb');
	}

	# FIXME: Log2udp for log file?

	# Webserver setup
	if ! defined( Class['webserver::php5'] ) {
		class { 'webserver::php5': }
	}
	apache_module { rewrite: name => 'rewrite' }
	apache_site { 'wikimania_scholarships': name => "${hostname}" }
	apache_confd {'namevirtualhost': install => true, name => 'namevirtualhost'}

	# Dependencies
	Class['webserver::php5'] ->
	Class['webserver::php5-mysql'] ->
	Apache_module['rewrite']

}
# vim:sw=4 ts=4 sts=4 noet:
