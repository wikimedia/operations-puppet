# misc/integration.pp

# CI test server as per RT #1204
class misc::contint::test {

	system_role { "misc::contint::test": description => "continuous integration test server" }

	class packages {
		# split up packages into groups a bit for readability and flexibility ("ensure present" vs. "ensure latest" ?)

		require generic::webserver::php5

		$CI_PHP_packages = [ "php-apc", "php5-cli", "php5-curl", "php5-gd", "php5-intl", "php5-mysql", "php-pear", "php5-sqlite", "php5-tidy", "php5-pgsql" ]
		$CI_DB_packages  = [ "mysql-server", "sqlite3", "postgresql" ]
		$CI_DEV_packages = [ "ant", "imagemagick" ]

		package { $CI_PHP_packages:
			ensure => present;
		}

		package { $CI_DB_packages:
			ensure => present;
		}

		package { $CI_DEV_packages:
			ensure => present;
		}

		include svn::client

		include generic::packages::git-core

		# Prefer the PHP packages from Ubuntu
		generic::apt::pin-package { $CI_PHP_packages: }

	}

	# Common apache configuration
	apache_module { ssl: name => "ssl" }
	apache_site { integration: name => "integration.mediawiki.org" }

	class jenkins {
		# first had code here to add the jenkins repo and key, but this package should be added to our own repo instead
		# package { "jenkins":
		#	ensure => present,
		#	require => File["jenkins.list"],
		#}

		service { 'jenkins':
			enable => true,
			ensure => 'running',
			hasrestart => true,
			start => '/etc/init.d/jenkins start',
			stop => '/etc/init.d/jenkins stop';
		}

		# nagios monitoring
		monitor_service { "jenkins": description => "jenkins_service_running", check_command => "check_jenkins_service" }

		file {
			# Top level jobs folder
			"/var/lib/jenkins/jobs/":
				owner => "jenkins",
				group => "wikidev",
				mode => 0775,
				ensure => directory;
			# Let wikidev users maintain the homepage
			 "/srv/org":
					mode => 0755,
					owner => www-data,
					group => wikidev,
					ensure => directory;
			 "/srv/org/mediawiki":
					mode => 0755,
					owner => www-data,
					group => wikidev,
					ensure => directory;
			 "/srv/org/mediawiki/integration":
					mode => 0755,
					owner => www-data,
					group => wikidev,
					ensure => directory;
			"/srv/org/mediawiki/integration/index.html":
				owner => www-data,
				group => wikidev,
				mode => 0555,
				source => "puppet:///files/misc/jenkins/index.html";
			# Placing the file in sites-available	
			"/etc/apache2/sites-available/integration.mediawiki.org":
				path => "/etc/apache2/sites-available/integration.mediawiki.org",
				mode => 0444,
				owner => root,
				group => root,
				source => "puppet:///files/apache/sites/integration.mediawiki.org";

		}

		# run jenkins behind Apache and have pretty URLs / proxy port 80
		# https://wiki.jenkins-ci.org/display/JENKINS/Running+Jenkins+behind+Apache

		apache_module { proxy: name => "proxy" }
		apache_module { proxy_http: name => "proxy_http" }

		file {
			"/etc/default/jenkins":
				owner => "root",
				group => "root",
				mode => 0444,
				source => "puppet:///files/misc/jenkins/etc_default_jenkins";
			"/etc/apache2/conf.d/jenkins_proxy":
				owner => "root",
				group => "root",
				mode => 0444,
				source => "puppet:///files/misc/jenkins/apache_proxy";
		}		
	}

	class testswarm {
		# Testswarm is configured using the debian package
		package { testswarm: ensure => latest; }

		# Create a user to run the cronjob with
		systemuser { testswarm:
			name  => "testswarm",
			home  => "/var/lib/testswarm",
			shell => "/bin/bash";
		}

		# install scripts
		file {
			"/var/lib/testswarm/script":
				require => Systemuser[testswarm],
				ensure  => directory,
				owner   => testswarm,
				group   => testswarm;
			"/var/lib/testswarm/script/testswarm-mw-fetcher-run.php":
				require => Systemuser[testswarm],
				ensure  => present,
				source  => "puppet:///files/testswarm/testswarm-mw-fetcher-run.php",
				owner   => testswarm,
				group   => testswarm;
			"/var/lib/testswarm/script/testswarm-mw-fetcher.php":
				require => Systemuser[testswarm],
				ensure  => present,
				source  => "puppet:///files/testswarm/testswarm-mw-fetcher.php",
				owner   => testswarm,
				group   => testswarm;
			# Directory that hold the mediawiki fetches
			"/var/lib/testswarm/mediawiki-trunk":
				require => Systemuser[testswarm],
				ensure  => directory,
				owner   => testswarm,
				group   => testswarm;
		}

		# Finally setup cronjob to fetch our files and setup a MediaWiki instance
		cron {
			testswarm-fetcher-mw-trunk:
				command => "(cd /var/lib/testswarm; php script/testswarm-mw-fetcher-run.php --prod) > mediawiki-trunk/cron.log 2>&1",
				user => testswarm,
				require => Systemuser[testswarm],
				ensure => present;
		}

	}

	# prevent users from accessing port 8080 directly (but still allow from localhost and own net)

	class iptables-purges {

		require "iptables::tables"

		iptables_purge_service{  "deny_all_http-alt": service => "http-alt" }
	}

	class iptables-accepts {

		require "misc::contint::test::iptables-purges"

		iptables_add_service{ "lo_all": interface => "lo", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "localhost_all": source => "127.0.0.1", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "private_all": source => "10.0.0.0/8", service => "all", jump => "ACCEPT" }
		iptables_add_service{ "public_all": source => "208.80.154.128/26", service => "all", jump => "ACCEPT" }
	}

	class iptables-drops {

		require "misc::contint::test::iptables-accepts"

		iptables_add_service{ "deny_all_http-alt": service => "http-alt", jump => "DROP" }
	}

	class iptables {

		require "misc::contint::test::iptables-drops"

		iptables_add_exec{ "${hostname}": service => "http-alt" }
	}
	
	require "misc::contint::test::iptables"
}
