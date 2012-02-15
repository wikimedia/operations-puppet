class misc::contint::jdk {
# JDK for android continuous integration
# extra stuff for license agreement acceptance
# Based off of http://offbytwo.com/2011/07/20/scripted-installation-java-ubuntu.html

	package { "debconf-utils":
		ensure => installed
	}

	exec { "agree-to-jdk-license":
		command => "/bin/echo -e sun-java6-jdk shared/accepted-sun-dlj-v1-1 select true | debconf-set-selections",
		unless => "debconf-get-selections | grep 'sun-java6-jdk.*shared/accepted-sun-dlj-v1-1.*true'",
		path => ["/bin", "/usr/bin"], require => Package["debconf-utils"],
	}

	exec { "agree-to-jre-license":
		command => "/bin/echo -e sun-java6-jre shared/accepted-sun-dlj-v1-1 select true | debconf-set-selections",
		unless => "debconf-get-selections | grep 'sun-java6-jre.*shared/accepted-sun-dlj-v1-1.*true'",
		path => ["/bin", "/usr/bin"], require => Package["debconf-utils"],
	}

	package { "sun-java6-jdk":
		ensure => latest,
		require => [ Exec["agree-to-jdk-license"] ],
	}

	package { "sun-java6-jre":
		ensure => latest,
		require => [ Exec["agree-to-jre-license"] ],
	}

}

class misc::contint::android::sdk {
	# Class installing prerequisites to the Android SDK
	# The SDK itself need to be installed manually for now.
	#
	# Help link: http://developer.android.com/sdk/installing.html

	# We really want Sun/Oracle JDK
	require misc::contint::jdk
	include generic::packages::ant18

	package { [
		"ia32-libs",
		"libswt-gtk-3.5-java"
		]: ensure => installed;
	}
}

# CI test server as per RT #1204
class misc::contint::test {

	system_role { "misc::contint::test": description => "continuous integration test server" }

	class packages {

		# Make sure we use ant version 1.8 or we will have a conflict
		# with android
		include generic::packages::ant18

		include generic::packages::maven

		# split up packages into groups a bit for readability and flexibility ("ensure present" vs. "ensure latest" ?)

		$CI_PHP_packages = [ "libapache2-mod-php5", "php-apc", "php5-cli", "php5-curl", "php5-gd", "php5-intl", "php5-mysql", "php-pear", "php5-sqlite", "php5-tidy", "php5-pgsql" ]
		$CI_DB_packages  = [ "mysql-server", "sqlite3", "postgresql" ]
		$CI_DEV_packages = [ "imagemagick" ]

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
		# This used to rely on misc::jenkins to add the jenkins upstream repo and then
		# install from there.  contint::misc::jenkins is now independent and will
		# use whatever Ubuntu version is available
		package { "jenkins":
			ensure => present
		}

		# Graphiz needed by the plugin that does the projects dependencies graph
		package { "graphviz":
			ensure => present
		}

		service { 'jenkins':
			enable => true,
			ensure => 'running',
			hasrestart => true,
			start => '/etc/init.d/jenkins start',
			stop => '/etc/init.d/jenkins stop';
		}

		# nagios monitoring
		monitor_service { "jenkins": description => "jenkins_service_running", check_command => "check_procs_generic!1!3!1!20!jenkins" }

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
			# Welcome page
			"/srv/org/mediawiki/integration/index.html":
				owner => www-data,
				group => wikidev,
				mode => 0555,
				source => "puppet:///files/misc/jenkins/index.html";
			# Stylesheet used by nightly builds (example: Wiktionary/Wikipedia mobiles apps)
			"/srv/org/mediawiki/integration/nightly.css":
				owner => www-data,
				group => wikidev,
				mode => 0555,
				source => "puppet:///files/misc/jenkins/nightly.css";
			"/srv/org/mediawiki/integration/WikipediaMobile":
				owner => jenkins,
				group => wikidev,
				mode => 0755,
				ensure => directory;
			# Copy HTML materials for ./WikipediaMobile/nightly/ :
			"/srv/org/mediawiki/integration/WikipediaMobile/nightly":
				owner => jenkins,
				group => wikidev,
				mode => 0755,
				ensure => directory,
				source => "puppet:///files/misc/jenkins/WikipediaMobile",
				recurse => "true";
			"/srv/org/mediawiki/integration/WiktionaryMobile":
				owner => jenkins,
				group => wikidev,
				mode => 0755,
				ensure => directory;
			"/srv/org/mediawiki/integration/WiktionaryMobile/nightly":
				owner => jenkins,
				group => wikidev,
				mode => 0755,
				ensure => directory,
				source => "puppet:///files/misc/jenkins/WiktionaryMobile",
				recurse => "true";
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

		class systemuser {
			# Create a user to run the cronjob with
			systemuser { testswarm:
				name  => "testswarm",
				home  => "/var/lib/testswarm",
				shell => "/bin/bash",
				# And part of web server user group so we can let it access
				# the SQLite databases
				groups => [ 'www-data' ];
			}
		}

		# Make sure we have a 'testswarm' user before doing anything else
		require misc::contint::test::testswarm::systemuser

		# Testswarm is configured using the debian package
		package { ["testswarm", "curl"]:
			ensure => latest; }

		# install scripts
		file {
			"/etc/testswarm":
				ensure => directory,
				mode   => 0755,
				owner  => testswarm,
				group  => testswarm;
			"/etc/testswarm/fetcher-sample.ini":
				require => [
					Package["testswarm"]
				],
				source  => "puppet:///files/testswarm/fetcher-sample.ini",
				mode    => 0660,
				owner   => testswarm,
				group   => testswarm;
			"/var/lib/testswarm/script":
				ensure  => directory,
				owner   => testswarm,
				group   => testswarm;
			"/var/lib/testswarm/script/testswarm-mw-fetcher-run.php":
				ensure  => present,
				source  => "puppet:///files/testswarm/testswarm-mw-fetcher-run.php",
				owner   => testswarm,
				group   => testswarm;
			"/var/lib/testswarm/script/testswarm-mw-fetcher.php":
				ensure  => present,
				source  => "puppet:///files/testswarm/testswarm-mw-fetcher.php",
				owner   => testswarm,
				group   => testswarm;
			# Directory that hold the mediawiki fetches
			"/var/lib/testswarm/mediawiki-trunk":
				ensure  => directory,
				owner   => testswarm,
				group   => testswarm;
			# SQLite databases files need specific user rights
			"/var/lib/testswarm/mediawiki-trunk/dbs":
				ensure  => directory,
				mode    => 0774,
				owner   => testswarm,
				group   => www-data;
			# Override Apache configuration coming from the testswarm package.
			"/etc/apache2/conf.d/testswarm.conf":
				ensure => absent;
		}

		# Reload apache whenever testswarm checkouts configuration change
		exec {	"update-testswarm-publish-checkout":
			command => "/usr/sbin/service apache2 reload",
			subscribe => File['/etc/apache2/sites-available/integration.mediawiki.org'],
			refreshonly => true,
			onlyif => "/usr/sbin/apache2ctl configtest"
		}

		# Finally setup cronjob to fetch our files and setup a MediaWiki instance
		cron {
			testswarm-fetcher-mw-trunk:
				command => "(cd /var/lib/testswarm; php script/testswarm-mw-fetcher-run.php --prod) >> mediawiki-trunk/cron.log 2>&1",
				minute => '*',
				user => testswarm,
				ensure => present;
		}

		# When a browser asks for jobs, it is reserved in the database so that
		# another similar browser does not run it also. If the client never
		# comes back with the result, it needs to be released.
		# ?state=wipe does things like that for entries not touched in over
		# 5 minutes and some other small maintenance
		cron {
			testswarm-state-wipe:
				require => Package["curl","testswarm"],
				command => "(/usr/bin/curl -s http://integration.mediawiki.org/testswarm/?state=wipe) > /dev/null",
				minute => '*',
				user => testswarm,
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
