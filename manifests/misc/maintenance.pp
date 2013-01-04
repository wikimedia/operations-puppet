# misc/maintenance.pp

# mw maintenance/batch hosts

class misc::maintenance::foundationwiki {

	system_role { "misc::maintenance::foundationwiki": description => "Misc - Maintenance Server: foundationwiki" }

	cron { 'updatedays':
		user => apache,
		minute => '*/15',
		command => '/usr/local/bin/mwscript extensions/ContributionReporting/PopulateFundraisingStatistics.php foundationwiki --op updatedays > /tmp/PopulateFundraisingStatistics-updatedays.log',
		ensure => present,
	}

	cron { 'populatefundraisers':
		user => apache,
		minute => 5,
		command => '/usr/local/bin/mwscript extensions/ContributionReporting/PopulateFundraisingStatistics.php foundationwiki --op populatefundraisers > /tmp/PopulateFundraisingStatistics-populatefundraisers.log',
		ensure => present,
	}
}

class misc::maintenance::refreshlinks {

	require mediawiki_new

	# Include this to add cron jobs calling refreshLinks.php on all clusters. (RT-2355)

	file { '/home/mwdeploy/refreshLinks':
		ensure => directory,
		owner => mwdeploy,
		group => mwdeploy,
		mode => 0664,
	}

	define cronjob() {

		$cluster = regsubst($name, '@.*', '\1')
		$monthday = regsubst($name, '.*@', '\1')

		cron { "cron-refreshlinks-${name}":
			command => "/usr/local/bin/mwscriptwikiset refreshLinks.php ${cluster}.dblist --dfn-only > /home/mwdeploy/refreshLinks/${name}.log 2>&1",
			user => mwdeploy,
			hour => 0,
			minute => 0,
			monthday => $monthday,
			ensure => present,
		}
	}

	# add cron jobs - usage: <cluster>@<day of month> (these are just needed monthly) (note: s1 is temp. deactivated)
	cronjob { ['s2@2', 's3@3', 's4@4', 's5@5', 's6@6', 's7@7']: }
}

class misc::maintenance::pagetriage {

	system_role { "misc::maintenance::pagetriage": description => "Misc - Maintenance Server: pagetriage extension" }

	cron { 'pagetriage_cleanup_en':
		user => apache,
		minute => 55,
 		hour => 20,
		monthday => '*/2',
		command => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php enwiki > /tmp/updatePageTriageQueue.en.log',
		ensure => present,
	}

	cron { 'pagetriage_cleanup_testwiki':
		user => apache,
		minute => 55,
		hour => 14,
		monthday => '*/2',
		command => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php testwiki > /tmp/updatePageTriageQueue.test.log',
		ensure => present,
	}
}

class misc::maintenance::translationnotifications {
	require misc::deployment::scripts

	# Should there be crontab entry for each wiki,
	# or just one which runs the scripts which iterates over
	# selected set of wikis?
	cron {
		translationnotifications-metawiki:
			command => "/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki metawiki 2>&1 >> /var/log/translationnotifications/digests.log",
			user => l10nupdate,  # which user?
			weekday => 1, # Monday
			hour => 10,
			minute => 0,
			ensure => present;

		translationnotifications-mediawikiwiki:
			command => "/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki mediawikiwiki 2>&1 >> /var/log/translationnotifications/digests.log",
			user => l10nupdate, # which user?
			weekday => 1, # Monday
			hour => 10,
			minute => 5,
			ensure => present;
	}

	file {
		"/var/log/translationnotifications":
			owner => l10nupdate, # user ?
			group => wikidev,
			mode => 0664,
			ensure => directory;
		"/etc/logrotate.d/l10nupdate":
			source => "puppet:///files/logrotate/translationnotifications",
			mode => 0444;
	}
}

class misc::maintenance::tor_exit_node {
	cron {
		tor_exit_node_update:
			command => "php /home/wikipedia/common/multiversion/MWScript.php extensions/TorBlock/loadExitNodes.php aawiki 2>&1",
			user => apache,
			minute => '*/20',
			ensure => present;
	}
}

class misc::maintenance::echo_mail_batch {
	cron {
		echo_mail_batch:
			command => "/usr/local/bin/mwscript extensions/Echo/processEchoEmailBatch.php testwiki",
			user => apache,
			minute => 0,
			hour => 0,
			ensure => present;
	}
}

class misc::maintenance::update_flaggedrev_stats{
	file {
		"/home/wikipedia/common/php/extensions/FlaggedRevs/maintenance/wikimedia-periodic-update.sh":
			source => "puppet:///files/misc/scripts/wikimedia-periodic-update.sh",
			owner => apache,
			group => wikidev,
			mode => 0755,
			ensure => present;
	}

	cron {
		update_flaggedrev_stats:
			command => "/home/wikipedia/common/php/extensions/FlaggedRevs/maintenance/wikimedia-periodic-update.sh 2>&1",
			user => "apache",
			hour => "*/2",
			minute => "0",
			ensure => present;
	}
}

class misc::maintenance::update_special_pages {
	cron {
		update_special_pages:
			command => "flock -n /var/lock/update-special-pages /usr/local/bin/update-special-pages > /home/wikipedia/logs/norotate/updateSpecialPages.log 2>&1",
			user => "apache",
			monthday => "*/3",
			hour => 5,
			minute => 0,
			ensure => present;
		update_special_pages_small:
			command => "flock -n /var/lock/update-special-pages-small /usr/local/bin/update-special-pages-small > /home/wikipedia/logs/norotate/updateSpecialPages-small.log 2>&1",
			user => "apache",
			monthday => "*/3",
			hour => 4,
			minute => 0,
			ensure => present;
	}

	file {
		"/usr/local/bin/update-special-pages":
			source => "puppet:///files/misc/scripts/update-special-pages",
			owner => apache,
			group => wikidev,
			mode => 0755,
			ensure => present;
		"/usr/local/bin/update-special-pages-small":
			source => "puppet:///files/misc/scripts/update-special-pages-small",
			owner => apache,
			group => wikidev,
			mode => 0755,
			ensure => present;
	}
}

class misc::maintenance::wikidata {
	cron {
		wikibase-repo-prune:
			command => "/usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki wikidatawiki --number-of-days=1 2>&1 >> /var/log/wikidata/prune.log",
			user => mwdeploy,
			minute => [0,15,30,45],
			ensure => present;
	}

	# Run the polling script every 5 minutes for test2.
	# This is a hack, and will be replaced before we roll it out to other wikis
	# We know it won't scale
	cron {
		wikibase-poll-test2:
			command => "/usr/local/bin/mwscript extensions/Wikibase/lib/maintenance/pollForChanges.php --wiki test2wiki --statefile=/home/wikipedia/common/wikibase-test2-poll.changeid --all 2>&1 >> /var/log/wikidata/poll.test2wiki.log",
			user => mwdeploy,
			minute => "*/5",
			ensure => present;
	}

	file {
		"/var/log/wikidata":
			owner => mwdeploy,
			group => mwdeploy,
			mode => 0664,
			ensure => directory;
		"/etc/logrotate.d/wikidata":
			source => "puppet:///files/logrotate/wikidata",
			mode => 0444;
	}
}

class misc::maintenance::parsercachepurging {

	system_role { "misc::maintenance::parsercachepurging": description => "Misc - Maintenance Server: parser cache purging" }

	cron { 'parser_cache_purging':
		user => apache,
		minute => 0,
		hour => 1,
		weekday => 0,
		# Purge entries older than 30d * 86400s/d = 2592000s
		command => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --age=2592000 >/dev/null 2>&1',
		ensure => present,
	}

}
