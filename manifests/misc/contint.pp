class misc::contint::android::sdk {
	# Class installing prerequisites to the Android SDK
	# The SDK itself need to be installed manually for now.
	#
	# Help link: http://developer.android.com/sdk/installing.html

	include generic::packages::ant18

	# 32bit libs needed by Android SDK
	# ..but NOT just all of ia32-libs ..
	package { [
		"libstdc++6:i386",
		"libgcc1:i386",
		"zlib1g:i386",
		"libncurses5:i386",
		"libsdl1.2debian:i386",
		"libswt-gtk-3.5-java"
		]: ensure => installed;
	}
}

# Includes packages needed for building
# analytics and statistics related packages.
# E.g. udp-filter, etc.
class misc::contint::analytics::packages {
	# these are needed to build libanon and udp-filter
	package { ["pkg-config", "libpcap-dev", "libdb-dev"]:
		ensure => "installed",
	}

        # these packages are used by the tests for wikistats to parse the
        # generated reports to see if they are correct
	package { ["libhtml-treebuilder-xpath-perl","libweb-scraper-perl"]:
		ensure => "installed",
	}
	# need geoip to build udp-filter
	include geoip
}

# CI test server as per RT #1204
class misc::contint::test {

	system_role { "misc::contint::test": description => "continuous integration test server" }

	class packages {
		include contint::packages
	}

	class jenkins {

		# Load the Jenkins module
		include ::jenkins

		# We need a basic site to publish nightly builds in
		include contint::website

		include contint::proxy_jenkins

		# Get several OpenJDK packages including the jdk.
		# (openjdk is the default distribution for the java define.
		# The java define is found in modules/java/manifests/init.pp )
		java { 'java-6-openjdk': version => 6, alternative => true  }
		java { 'java-7-openjdk': version => 7, alternative => false }

		include ::contint::tmpfs

		file {
			"/var/lib/jenkins/.gitconfig":
				mode => 0444,
				owner => "jenkins",
				group => "jenkins",
				ensure => present,
				source => "puppet:///files/misc/jenkins/gitconfig",
				require => User['jenkins'];
		}

		file {
			"/var/lib/jenkins/.git":
				mode   => 2775,  # group sticky bit
				group  => "jenkins",
				ensure => directory;
			"/var/lib/jenkins/bin":
				owner => "jenkins",
				group => "wikidev",
				mode => 0775,
				ensure => directory;
			# Welcome page
			"/srv/org/mediawiki/integration/index.html":
				owner => www-data,
				group => wikidev,
				mode => 0444,
				source => "puppet:///files/misc/jenkins/index.html";
			# Stylesheet used by nightly builds (example: Wiktionary/Wikipedia mobiles apps)
			"/srv/org/mediawiki/integration/nightly.css":
				owner => www-data,
				group => wikidev,
				mode => 0444,
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
				mode => 0644,
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
				mode => 0644,
				ensure => directory,
				source => "puppet:///files/misc/jenkins/WiktionaryMobile",
				recurse => "true";
			"/srv/org/mediawiki/integration/WLMMobile":
				owner => jenkins,
				group => wikidev,
				mode => 0755,
				ensure => directory;
			"/srv/org/mediawiki/integration/WLMMobile/nightly":
				owner => jenkins,
				group => wikidev,
				mode => 0644,
				ensure => directory,
				source => "puppet:///files/misc/jenkins/WLMMobile",
				recurse => "true";
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
		iptables_add_service{ "public_all": source => "208.80.152.0/22", service => "all", jump => "ACCEPT" }
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
