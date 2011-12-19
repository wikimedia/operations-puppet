# search.pp

# Virtual resource for the monitoring server
@monitor_group { "lucene": description => "pmtpa search servers" }

class search {

	class server($indexer="false", $pool="", $udplogging="true") {
		Class["search::config"] -> Class[search::server]
	
		include search::sudo
		include search::jvm
		include search::monitoring
		
		if $indexer == "true" {
			include search::indexer
		}
	}

	class config {
		file {
			"/etc/lsearch.conf":
				owner => root,
				group => root,
				mode => 0444,
				content => template("lucene/lsearch.conf.erb"),
				ensure => present;
			"/etc/lsearch-global-2.1.conf":
				owner => root,
				group => root,
				mode => 0444,
				content => template("lucene/lsearch-global-2.1.conf.erb"),
				ensure => present;
		}
	}

	class sudo {
		file { "/etc/sudoers":
			owner => root,
			group => root,
			mode => 0440,
			source => "puppet:///files/sudo/sudoers.search",
			ensure => present;
		}
	}

	class jvm {
		# FIXME: build replacement packages

		# These packages are no longer available in Lucid
		if $lsbdistid == "Ubuntu" and versioncmp($lsbdistrelease, "10.04") < 0 {
			package { ia32-sun-java6-bin:
				ensure => latest;
			}

			$jvm = $hostname ? {
				/search(11|13)/	=> "/usr/lib/jvm/java-6-openjdk/jre/bin/java",
				default		=> "/usr/lib/jvm/ia32-java-6-sun/jre/bin/java",
			}

			exec { jvm-alternatives:
				command => "/usr/sbin/update-alternatives --set java $jvm"
			}
		}
	}

	class monitoring {
		if $pool {
			monitor_service { "lucene": description => "Lucene", check_command => "check_lucene", retries => 6 }
		}
		if $indexer == "true" {
			monitor_service { "lucene_indexer": description => "Lucene indexer", check_command => "check_lucene_indexer", retries => 6 }
		}
	}

	class indexer {

		include passwords::lucene
		$lucene_oai_pass = $passwords::lucene::oai_pass

		class { 'generic::rsyncd': config => "searchidx" }
		
		file { "/etc/php5/apache2/php.ini":
			owner => root,
			group => root,
			mode => 0440,
			source => "puppet:///files/php/php.ini.appserver";
		}
		## TO DO: pull these out of rainman's homedir and into something not on nfs
		cron {
			snapshot:
				#require => ,
				command => "/home/rainman/scripts/search-snapshot",
				user => rainman,
				hour => 4,
				minute => 30,
				ensure => present;
			snapshot-precursors:
				#require => ,
				command => "/home/rainman/scripts/search-snapshot-precursors",
				user => rainman,
				weekday => 5,
				hour => 9,
				minute => 30,
				ensure => present;	
			indexer-cron:
				#require => ,
				command => "/home/rainman/scripts/indexer-cron",
				user => rainman,
				weekday => 6,
				hour => 0,
				minute => 0,
				ensure => present;
			import-private-cron:
				#require => ,
				command => "/home/rainman/scripts/search-import-private-cron",
				user => rainman,
				hour => 2,
				minute => 0,
				ensure => present;
			import-broken-cron:
				#require => ,
				command => "/home/rainman/scripts/search-import-broken-cron",
				user => rainman,
				hour => 3,
				minute => 0,
				ensure => present;
			build-prefix:
				#require => ,
				command => "/home/rainman/scripts/search-build-prefix",
				user => rainman,
				hour => 9,
				minute => 25,
				ensure => present;
		}
	}
}
