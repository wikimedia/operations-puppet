# TODO: break this up in different (sub) classes for the different services
class misc::fundraising {

	include passwords::civi

	#what is currently on grosley/aluminium
	system_role { "misc::fundraising": description => "fundraising sites and operations" }

	require mysql::client

	package { [ "libapache2-mod-php5", "php5-cli", "php-pear", "php5-common", "php5-curl", "php5-dev", "php5-gd", "php5-mysql", "php5-sqlite", "subversion", "phpunit", "python-scipy", "python-matplotlib", "python-libxml2", "python-sqlite", "python-sqlitecachec", "python-urlgrabber", "python-argparse", "python-dev", "python-setuptools", "python-mysqldb", "libapache2-mod-python" ]:
		ensure => latest;
	}

	file {
		#civicrm confs
		"/srv/org.wikimedia.civicrm/sites/default/civicrm.settings.php":
			mode => 0440,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/civicrm.civicrm.settings.php";
		"/srv/org.wikimedia.civicrm/sites/default/default.settings.php":
			mode => 0440,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/civicrm.default.settings.php";
		"/srv/org.wikimedia.civicrm/sites/default/settings.php":
			mode => 0440,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/civicrm.settings.php";

		#civicrm dev confs
		"/srv/org.wikimedia.civicrm-dev/sites/default/civicrm.settings.php":
			mode => 0440,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/dev.civicrm.civicrm.settings.php";
		"/srv/org.wikimedia.civicrm-dev/sites/default/default.settings.php":
			mode => 0440,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/dev.civicrm.default.settings.php";
		"/srv/org.wikimedia.civicrm-dev/sites/default/settings.php":
			mode => 0440,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/dev.civicrm.settings.php";

		#misc fundraising confs
		"/opt/fundraising-misc/queue_handling/payflowpro/executeStompPFPPendingProcessorSA.php":
			mode => 0444,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/misc.executeStompPFPPendingProcessorSA.php";
		"/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Recurring.php":
			mode => 0444,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/misc.IPNListener_Recurring.php";
		"/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Standalone.php":
			mode => 0444,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/misc.IPNListener_Standalone.php";
		"/opt/fundraising-misc/auditing/paypal-audit/auth.cfg":
			mode => 0444,
			owner => www-data,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/fundraising-misc.auth.cfg";
		"/opt/fundraising-misc/public_reporting/update_config.php":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/fundraising-misc.update_config.php";
		"/srv/org.wikimedia.fundraising/IPNListener_Standalone.php":
			ensure => "/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Standalone.php";
		"/srv/org.wikimedia.civicrm/fundcore_gateway/paypal":
			ensure => "/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Standalone.php";
		"/srv/org.wikimedia.civicrm/IPNListener_Recurring.php":
			ensure => "/opt/fundraising-misc/queue_handling/paypal/IPN/IPNListener_Recurring.php";
		"/srv/org.wikimedia.civicrm/files":
			owner => "www-data",
			group => "wikidev",
			mode => 0775,
			ensure => directory;
		"/srv/org.wikimedia.civicrm-dev/files":
			owner => "www-data",
			group => "wikidev",
			mode => 0775,
			ensure => directory;
		"/srv/org.wikimedia.civicrm/fundcore_gateway":
			owner => "www-data",
			group => "wikidev",
			mode => 0775,
			ensure => directory;
		"/srv/org.wikimedia.civicrm/fundcore_gateway/.htaccess":
			owner => "www-data",
			group => "wikidev",
			mode => 0444,
			content => "<Files paypal>
	ForceType application/x-httpd-php
</Files>";

		#apache conf stuffs
		"/etc/php5/apache2/php.ini":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/php/php.ini.civicrm";
		"/etc/apache2/sites-available/000-donate":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.donate";
		"/etc/apache2/sites-available/002-civicrm":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.civicrm";
		"/etc/apache2/sites-available/003-civicrm-ssl":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.civicrm-ssl";
		"/etc/apache2/sites-available/004-civicrm-dev":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.civicrm-dev";
		"/etc/apache2/sites-available/005-civicrm-dev-ssl":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.civicrm-dev-ssl";
		"/etc/apache2/sites-available/006-fundraising":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.fundraising";
		"/etc/apache2/sites-available/007-fundraising-analytics":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/apache.conf.fundraising-analytics";

		"/usr/local/bin/drush":
			ensure => "/opt/drush/drush";

		# other stuff
		"/etc/php5/cli/php.ini":
			mode => 0444,
			owner => root,
			group => root,
			source => "puppet:///private/php/php.ini.fundraising.cli";
		"/usr/local/bin/sync_archive_to_storage3":
			mode => 0500,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/sync_archive_to_storage3";
	}

	#enable apache mods
	apache_module { rewrite: name => "rewrite" }
	apache_module { ssl: name => "ssl" }

	#enable apache sites
	apache_site { donate: name => "000-donate" }
	apache_site { civicrm: name => "002-civicrm" }
	apache_site { civicrm-ssl: name => "003-civicrm-ssl" }
	apache_site { civicrm-dev: name => "004-civicrm-dev" }
	apache_site { civicrm-dev-ssl: name => "005-civicrm-dev-ssl" }
	apache_site { fundraising: name => "006-fundraising" }
	apache_site { fundraising-analytics: name => "007-fundraising-analytics" }

}

class misc::fundraising::impressionlog::compress {

	file { 
		'/usr/local/bin/impression_log_rotator':
			mode => 0755,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/impression_log_rotator";
	}

	cron {
		'rotate_impression_logs':
			user => root,
			minute => '*/5',
			command => '/usr/local/bin/impression_log_rotator',
			ensure => present,
	}

}


class misc::fundraising::offhost_backups {

	file { 
		'/usr/local/bin/offhost_backups':
			mode => 0755,
			owner => root,
			group => root,
			source => 'puppet:///files/misc/scripts/offhost_backups',
	}

	#cron {
	#	'offhost_backups':
	#		user => root,
	#		minute => '35',
	#		hour => '1',
	#		command => '/usr/local/bin/offhost_backups',
	#		ensure => present,
	#}

}

class misc::fundraising::jenkins_maintenance {

	file {
		"/usr/local/bin/jenkins_watcher":
			mode => 0500,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/jenkins_watcher";
		"/usr/local/bin/jenkins_archiver":
			mode => 0500,
			owner => root,
			group => root,
			source => "puppet:///private/misc/fundraising/jenkins_archiver";
	}

	cron {
		'jenkins_archiver':
			user => root,
			minute => '50',
			command => '/usr/local/bin/jenkins_archiver',
			ensure => present;
		'jenkins_watcher':
			user => root,
			minute => '*/5',
			command => '/usr/local/bin/jenkins_watcher',
			ensure => present;
	}

}

class misc::fundraising::mail {

	system_role { "misc::fundraising::mail": description => "fundraising mail server" }

	package { [ "dovecot-imapd", "exim4-daemon-heavy", "exim4-config" ]:
		ensure => latest;
	}

	group { civimail:
		ensure => "present",
	}

	user { civimail:
		name => "civimail",
		gid => "civimail",
		groups => [ "civimail" ],
		membership => "minimum",
		password => $passwords::civi::civimail_pass,
		home => "/home/civimail",
		shell => "/bin/sh";
	}

	file {
		"/etc/exim4/exim4.conf":
			content => template("exim/exim4.donate.erb"),
			mode => 0444,
			owner => root,
			group => root;
		"/etc/exim4/wikimedia.org-fundraising-private.key":
			mode => 0440,
			owner => root,
			group => Debian-exim,
			source => "puppet:///private/dkim/wikimedia.org-fundraising-private.key";
		"/etc/dovecot/dovecot.conf":
			source => "puppet:///files/dovecot/dovecot.donate.conf",
			mode => 0444,
			owner => root,
			group => root;
		"/var/mail/civimail":
			owner => "civimail",
			group => "civimail",
			mode => 2755,
			ensure => directory;
		"/usr/local/bin/collect_exim_stats_via_gmetric":
			source => "puppet:///files/ganglia/collect_exim_stats_via_gmetric",
			mode => 0755,
			owner => root,
			group => root;
		"/usr/local/bin/civimail_send":
			mode => 0710,
			owner => root,
			group => wikidev,
			source => "puppet:///private/misc/fundraising/civimail_send";
	}

	cron {
		'collect_exim_stats_via_gmetric':
			user => root,
			command => '/usr/local/bin/collect_exim_stats_via_gmetric',
			ensure => present;
		'exim_queue_count_for_mailer_script':
			user => root,
			command => '/usr/sbin/exim -bpc > /tmp/exim_queue_count.dat',
			ensure => present;
	}

}
