# search.pp

# Virtual resource for the monitoring server
@monitor_group { "lucene": description => "pmtpa search servers" }

class lucene {

	class server($indexer=false, $udplogging=true) {
		Class["lucene::config"] -> Class[lucene::server]
		Class["lucene::packages"] -> Class[lucene::server]

		include passwords::lucene
		$lucene_oai_pass = $passwords::lucene::oai_pass

		include lucene::packages,
			lucene::config,
			lucene::service,
			lucene::monitoring

		if $indexer == true {
			include lucene::indexer
		}
	}

	class packages {
		package { 
			["oracle-j2sdk1.6", "libudp2log-log4j-java"]:
				ensure => latest;
			"liblog4j1.2-java":
				require => Package["oracle-j2sdk1.6"],
				ensure => latest;
			"lucene-search-2":
				require => Package["oracle-j2sdk1.6"],
				# Present instead of latest for controlled upgrade
				ensure => present;
		}
	}

	class config {
		require role::lucene::configuration

		file {
			"/a/search/conf/lsearch-global-2.1.conf":
				require => File["/a/search/conf"],
				owner => lsearch,
				group => search,
				mode => 0444,
				content => template("lucene/lsearch-global-2.1.conf.erb"),
				ensure => present;
			"/etc/lsearch.conf":
				owner => lsearch,
				group => search,
				mode => 0444,
				content => template("lucene/lsearch.conf.erb"),
				ensure => present;
			"/a/search/conf/lsearch.log4j":
				require => File["/a/search/conf"],
				owner => lsearch,
				group => search,
				mode => 0444,
				content => template("lucene/lsearch.log4j.erb"),
				ensure => present;
			[ "/a/search", "/a/search/indexes", "/a/search/log", "/a/search/conf", "/a/search/dumps" ]:
				ensure => directory,
				owner => lsearch,
				group => search,
				mode => 0775;
		}
		if $lucene::server::indexer == true {
			file {
				"/etc/logrotate.d/lucene-indexer":
					owner => root,
					group => root,
					mode => 0444,
					source => "puppet:///files/logrotate/search-indexer",
					ensure => present;
				}
		}

		# Conf for sync-conf-from-common cronjob
		if $::realm == 'production' {
			$sync_conf_all_dblist = '10.0.5.8::common/all.dblist'
			$sync_conf_initialisesettings = '10.0.5.8::common/wmf-config/InitialiseSettings.php'
			$sync_conf_initialisesettings_labs = ''
			$sync_conf_messages = '10.0.5.8::common/php/languages/messages'
		} else {
			$sync_conf_all_dblist = '/data/project/apache/common/all-labs.dblist'
			$sync_conf_initialisesettings = '/data/project/apache/common/wmf-config/InitialiseSettings.php'
			$sync_conf_initialisesettings_labs = '/data/project/apache/common/wmf-config/InitialiseSettings-labs.php'
			$sync_conf_messages = '/data/project/apache/common/php-master/languages/messages'
		}
		cron {
			## to occassionally poll for mediawiki configs
			sync-conf-from-common:
				require => File["/a/search/conf"],
				command => "rsync -a --delete --exclude=**/.svn/lock --no-perms ${sync_conf_all_dblist} /a/search/conf/ && rsync -a --delete --exclude=**/.svn/lock --no-perms ${sync_conf_initialisesettings} ${sync_conf_initialisesettings_labs} /a/search/conf/ && rsync -a --delete --exclude=**/.svn/lock --no-perms ${sync_conf_messages} /a/search/conf/",
				user => lsearch,
				minute => 15,
				ensure => present;
		}

		cron {
			## this is to compliment log4j's log rotation. we want to use log4j's logrotate ability, as it's easier on the system,
			## but log4j does not yet have "delete old logs" capability :/
			delete-old-logs:
				command =>'find /a/search/log/log.* -type f -mtime +3 -exec rm -f {} \;',
				user => lsearch,
				hour => 0,
				minute => 0,
				ensure => present;
		}

	}

	class service {
		service { lucene-search-2:
			ensure => running,
			require => [ File["/etc/lsearch.conf"], File["/a/search/conf/lsearch-global-2.1.conf"], File["/a/search/indexes"], File["/a/search/log"] ];
		}

		if $lucene::server::indexer == false {
			monitor_service { "lucene": description => "Lucene", check_command => "check_lucene", retries => 6 }

			# Each box hosts different databases
			monitor_service { 'lucene_search': description => 'Lucene search', check_command => "check_lucene_frontend!$lucene_project_to_check" }
		}
	}

	class monitoring {
		monitor_service { "lucene disk space": description => "Lucene disk space", check_command => "nrpe_check_disk_6_3"}
	}

	class users {
		include groups::search
		systemuser { "lsearch": name => "lsearch", default_group => "search"}
	}

	class indexer {

		class { 'generic::rsyncd': config => "searchidx" }

		file {
			"/a/search/conf/nooptimize.dblist":
				owner => lsearch,
				group => search,
				mode => 0444,
				source => "puppet:///files/lucene/nooptimize.dblist";
			"/a/search/lucene.jobs.sh":
				owner => lsearch,
				group => search,
				mode => 0755,
				source => "puppet:///files/lucene/lucene.jobs.sh";
		}

		cron {
			snapshot:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh snapshot',
				user => lsearch,
				hour => 4,
				minute => 30,
				ensure => present;
			snapshot-precursors:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh snapshot-precursors',
				user => lsearch,
				weekday => 5,
				hour => 9,
				minute => 30,
				ensure => present;
			indexer-cron:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh indexer-cron',
				user => lsearch,
				weekday => 6,
				hour => 0,
				minute => 0,
				ensure => present;
			import-private:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh import-private',
				user => lsearch,
				hour => 2,
				minute => 0,
				ensure => present;
			import-broken:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh import-broken',
				user => lsearch,
				hour => 3,
				minute => 0,
				ensure => present;
			build-prefix:
				require => File["/a/search/lucene.jobs.sh"],
				command => '/a/search/lucene.jobs.sh build-prefix',
				user => lsearch,
				hour => 9,
				minute => 25,
				ensure => present;
		}
	}
}

class search::searchqa::phase1 {
	file {
		'/opt/searchqa':
			ensure => directory,
			owner => root,
			group => wikidev,
			mode  => 0755;
	}
}

class search::searchqa {
	require search::searchqa::phase1
	file {
		'/opt/searchqa/bin':
			recurse => true,
			purge => true,
			force => true,
			owner => root,
			group => wikidev,
			mode  => 0555,
			source => "puppet:///files/searchqa/bin";
		'/opt/searchqa/lib':
			recurse => true,
			purge => true,
			force => true,
			owner => root,
			group => wikidev,
			mode  => 0644,
			source => "puppet:///files/searchqa/lib";
		'/opt/searchqa/data':
			ensure => directory,
			owner => root,
			group => wikidev,
			mode  => 0774;
	}
}
