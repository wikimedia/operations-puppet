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
			mode => 0555,
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

		include passwords::lucene
		$lucene_oai_pass = $passwords::lucene::oai_pass

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
		if $indexer == "true" {
			include mediawiki::packages

			# FIXME: what installs apache2? Let's make sure that doesn't happen for search hosts
			service { apache2:
				ensure => stopped
			}
		}
	}

	class config {
		# FIXME: use one template for all sites?
		if $::site == "pmtpa" {
			file { "/a/search/conf/lsearch-global-2.1.conf":
				require => File["/a/search/conf"],
				# FIXME: why does rainman own a file that is managed by Puppet?
				owner => rainman,
				group => search,
				mode => 0444,
				content => template("lucene/lsearch-global-2.1.conf.pmtpa.erb"),
				ensure => present;
			}
		}
		if $::site == "eqiad" {
			file { "/a/search/conf/lsearch-global-2.1.conf":
				require => File["/a/search/conf"],
				owner => rainman,
				group => search,
				mode => 0444,
				content => template("lucene/lsearch-global-2.1.conf.eqiad.erb"),
				ensure => present;
			}
		}
		# FIXME: why does rainman own files that are managed by Puppet?
		file {
			"/etc/lsearch.conf":
				owner => rainman,
				group => search,
				mode => 0444,
				content => template("lucene/lsearch.conf.new.erb"),
				ensure => present;
			"/a/search/conf/lsearch.log4j":
				require => File["/a/search/conf"],
				owner => rainman,
				group => search,
				mode => 0444,
				source => "puppet:///files/lucene/lsearch.log4j",
				ensure => present;
			[ "/a/search", "/a/search/indexes", "/a/search/log", "/a/search/conf" ]:
				ensure => directory,
				owner => rainman,
				group => search,
				mode => 0775;
		
			## log rotation
			"/etc/logrotate.d/lucene":
				owner => root,
				group => root,
				mode => 0444,
				source => "puppet:///files/logrotate/search",
				ensure => present;
		}
		if $indexer == "true" {
			file {
				"/etc/logrotate.d/lucene-indexer":
					owner => root,
					group => root,
					mode => 0444,
					source => "puppet:///files/logrotate/search-indexer",
					ensure => present;
				}
		}

		## to occassionally poll for mediawiki configs
		cron { sync-conf-from-common:
			require => File["/a/search/conf"],
			command => 'rsync -a --delete --exclude=**/.svn/lock --no-perms 10.0.5.8::common/all.dblist /a/search/conf/ && rsync -a --delete --exclude=**/.svn/lock --no-perms 10.0.5.8::common/wmf-config/InitialiseSettings.php /a/search/conf/ && rsync -a --delete --exclude=**/.svn/lock --no-perms 10.0.5.8::common/php/languages/messages /a/search/conf/',
			user => rainman,
			minute => 5,
			ensure => present;
		}

		# FIXME: duplicate of stuff in mediawiki app servers? Pull a class in from there if needed
		if $indexer == "true" {
			file {
				"/etc/php5/conf.d/fss.ini":
					owner => root,
					group => root,
					mode => 0444,
					source => "puppet:///files/php/fss.ini.appserver";
				"/etc/php5/apache2/php.ini":
					owner => root,
					group => root,
					mode => 0444,
					source => "puppet:///files/php/php.ini.appserver";
			}
		}
	}

	class service {
		service { lucene-search-2:
			ensure => running,
			require => [ File["/etc/lsearch.conf"], File["/a/search/conf/lsearch-global-2.1.conf"], File["/a/search/indexes"], File["/a/search/log"] ];		
		}

		if $indexer != "true" {
			monitor_service { "lucene": description => "Lucene", check_command => "check_lucene", retries => 6 }
		}
	}

	# FIXME: migrate this to sudo_users and stock /etc/sudoers file
	class users {
		file { "/etc/sudoers":
			owner => root,
			group => root,
			mode => 0440,
			source => "puppet:///files/sudo/sudoers.search",
			ensure => present;
		}

		systemuser { "lsearch": name => "lsearch", default_group => "search"}
	}

	class indexer {

		class { 'generic::rsyncd': config => "searchidx" }

		file { 
			"/a/search/conf/nooptimize.dblist":
				owner => rainman,
				group => search,
				mode => 0444,
				source => "puppet:///files/lucene/nooptimize.dblist";
			"/a/search/lucene.jobs.sh":
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
			import-private:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh import-private',
				user => rainman,
				hour => 2,
				minute => 0,
				ensure => present;
			import-broken:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh import-broken',
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
