# search.pp

# Virtual resource for the monitoring server
@monitor_group { "lucene": description => "pmtpa search servers" }

class search::sudo {
	file { "/etc/sudoers":
		owner => root,
		group => root,
		mode => 0440,
		source => "puppet:///files/sudo/sudoers.search",
		ensure => present;
	}
}

class search::logrotate {
	file {
		 "/etc/cron.daily/logrotate":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/logrotate/logrotate.cron.daily.search",
			ensure => present;
		 "/etc/logrotate.d/wikimedia-task-search":
			owner => root,
			group => root,
			mode => 0444,
			source => "puppet:///files/logrotate/search",
			ensure => present;
	}
}

class search::php {
	file { "/etc/php5/apache2/php.ini":
		owner => root,
		group => root,
		mode => 0440,
		source => "puppet:///files/php/php.ini.appserver";
	}
}

class search::jvm {
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

class search::monitoring {
	if ! $search_indexer {
		monitor_service { "lucene": description => "Lucene", check_command => "check_lucene", retries => 6 }
	}
}

class search::indexer {

	include passwords::lucene
	$lucene_oai_pass = $passwords::lucene::oai_pass

	package { nfs-common:
                ensure => latest;
        }

	file { "/etc/lsearch.conf":
		owner => root,                                                                                                                                                 
                group => root,                                                                                                                                                 
                mode => 0644,
		content => template("lucene/lsearch.conf.erb"),
		ensure => present;
	}

	file { "/etc/default/rsync":
                owner => root,
                group => root,
                mode => 0644,
                source => "puppet:///files/rsync/rsync.default",
                ensure => present;
        }

	file { "/etc/rsyncd.conf":
                owner => root,
                group => root,
                mode => 0644,
                source => "puppet:///files/rsync/rsyncd.conf.searchidx",
                ensure => present;
        }

	service { "rsync" :
		ensure => running,
		enable => true,
		hasstatus => false,
		require => [ File["/etc/default/rsync"], File["/etc/rsyncd.conf"] ]
	}
}

# new lucene class for better naming convention and migration to new 
# puppet-based lucene setup

class lucene {

	class server($indexer="false", $udplogging="true") {
		Class["lucene::config"] -> Class[lucene::server]
		Class["lucene::packages"] -> Class[lucene::server]

		include lucene::packages,
			lucene::config,
			lucene::service

		if $indexer == "true" {
			include lucene::indexer
		}
	}

	class packages {
		package { ["sun-j2sdk1.6", "lucene-search-2"]:
			ensure => latest;
		}
		package { ["liblog4j1.2-java"]:
			require => Package["sun-j2sdk1.6"],
			ensure => latest;
		}
# need to figure out what the indexer in particular needs.
#		if $indexer == "true" {
#			package { :
#				ensure => latest;
#			}
#		}
	}

	class config {
		file {
			"/etc/lsearch.conf":
				owner => root,
				group => root,
				mode => 0444,
				content => template("lucene/lsearch.conf.new.erb"),
				ensure => present;
			"/a/search/conf/lsearch.log4j":
				require => File["/a/search/conf"],
				owner => root,
				group => root,
				mode => 0444,
				source => "puppet:///files/lucene/lsearch.log4j",
				ensure => present;
			"/a/search/conf/lsearch-global-2.1.conf":
				require => File["/a/search/conf"],
				owner => root,
				group => root,
				mode => 0444,
				content => template("lucene/lsearch-global-2.1.conf.erb"),
				ensure => present;
			[ "/a/search/indexes", "/a/search/log", "/a/search/conf" ]:
                                ensure => directory,
                                owner => rainman,
                                group => search,
				mode => 0775,
				require => Package[lucene-search-2];
		
			## log rotation bits and pieces
			"/etc/logrotate.d/lucene":
				owner => root,
				group => root,
				mode => 0444,
				source => "puppet:///files/logrotate/search",
				ensure => present;
			 "/etc/cron.daily/logrotate":
				owner => root,
				group => root,
				mode => 0444,
				source => "puppet:///files/logrotate/logrotate.cron.daily.search",
				ensure => present;
		}
	}

	class service {
		service { lucene-search-2:
			ensure => running,
			require => [ File["/etc/lsearch.conf", "/a/search/conf/lsearch-global-2.1.conf", "/a/search/indexes", "/a/search/log"], Package[lucene-search-2] ]
		}

		monitor_service { "lucene": description => "Lucene", check_command => "check_lucene", retries => 6 }
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

		monitor_service { "lucene_indexer": description => "Lucene indexer", check_command => "check_lucene_indexer", retries => 6 }

		## TO DO: pull these out of rainman's homedir and into something not on nfs

		file { "/a/search/lucene.jobs.sh":
			owner => rainman,
			group => search,
			mode => 0755,
			source => "puppet:///files/lucene/lucene.jobs.sh";
		}

		cron {
			snapshot:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh snapshot',
				user => rainman,
				hour => 4,
				minute => 30,
				ensure => present;
			snapshot-precursors:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh snapshot-precursors',
				user => rainman,
				weekday => 5,
				hour => 9,
				minute => 30,
				ensure => present;	
			indexer-cron:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh indexer-cron',
				user => rainman,
				weekday => 6,
				hour => 0,
				minute => 0,
				ensure => present;
			import-private-cron:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh import-private-cron',
				user => rainman,
				hour => 2,
				minute => 0,
				ensure => present;
			import-broken-cron:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh import-broken-cron',
				user => rainman,
				hour => 3,
				minute => 0,
				ensure => present;
			build-prefix:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh build-prefix',
				user => rainman,
				hour => 9,
				minute => 25,
				ensure => present;
		}
	}
}
