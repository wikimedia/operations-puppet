# misc/maintenance.pp

# mw maintenance/batch hosts

class misc::maintenance {
	$default_ensure = $::mw_primary ? {
		$::site => present,
		default => absent
	}
}

class misc::maintenance::foundationwiki( $enabled = undef ) {

	system_role { "misc::maintenance::foundationwiki": description => "Misc - Maintenance Server: foundationwiki" }

	$ensure = $enabled ? {
		true => present,
		false => absent,
		default => $misc::maintenance::default_ensure
	}
	cron {
		'updatedays':
			user => apache,
			minute => '*/15',
			command => '/usr/local/bin/mwscript extensions/ContributionReporting/PopulateFundraisingStatistics.php foundationwiki --op updatedays > /tmp/PopulateFundraisingStatistics-updatedays.log',
			ensure => $ensure;
		'populatefundraisers':
			user => apache,
			minute => 5,
			command => '/usr/local/bin/mwscript extensions/ContributionReporting/PopulateFundraisingStatistics.php foundationwiki --op populatefundraisers > /tmp/PopulateFundraisingStatistics-populatefundraisers.log',
			ensure => $ensure;
	}
}

class misc::maintenance::refreshlinks( $enabled = undef ) {

	require mediawiki

	# Include this to add cron jobs calling refreshLinks.php on all clusters. (RT-2355)

	file { '/home/mwdeploy/refreshLinks':
		ensure => directory,
		owner => mwdeploy,
		group => mwdeploy,
		mode => 0664,
	}

	define cronjob( $cronenabled = $enabled ) {

		$cluster = regsubst($name, '@.*', '\1')
		$monthday = regsubst($name, '.*@', '\1')

		cron { "cron-refreshlinks-${name}":
			command => "/usr/local/bin/mwscriptwikiset refreshLinks.php ${cluster}.dblist --dfn-only > /home/mwdeploy/refreshLinks/${name}.log 2>&1",
			user => mwdeploy,
			hour => 0,
			minute => 0,
			monthday => $monthday,
			ensure => $cronenabled ?{
				true => present,
				false => absent,
				default => $misc::maintenance::default_ensure
			};
		}
	}

	# add cron jobs - usage: <cluster>@<day of month> (these are just needed monthly) (note: s1 is temp. deactivated)
	cronjob { ['s2@2', 's3@3', 's4@4', 's5@5', 's6@6', 's7@7']: }
}

class misc::maintenance::pagetriage( $enabled = undef ) {

	system_role { "misc::maintenance::pagetriage": description => "Misc - Maintenance Server: pagetriage extension" }

	$ensure = $enabled ?{
		true => present,
		false => absent,
		default => $misc::maintenance::default_ensure
	}

	cron {
		'pagetriage_cleanup_en':
			user => apache,
			minute => 55,
			hour => 20,
			monthday => '*/2',
			command => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php enwiki > /tmp/updatePageTriageQueue.en.log',
		'pagetriage_cleanup_testwiki':
			user => apache,
			minute => 55,
			hour => 14,
			monthday => '*/2',
			command => '/usr/local/bin/mwscript extensions/PageTriage/cron/updatePageTriageQueue.php testwiki > /tmp/updatePageTriageQueue.test.log',
			ensure => $ensure;
	}
}

class misc::maintenance::translationnotifications( $enabled = undef ) {
	require misc::deployment::scripts

	$ensure = $enabled ?{
		true => present,
		false => absent,
		default => $misc::maintenance::default_ensure
	}

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
			ensure => $ensure;
		translationnotifications-mediawikiwiki:
			command => "/usr/local/bin/mwscript extensions/TranslationNotifications/scripts/DigestEmailer.php --wiki mediawikiwiki 2>&1 >> /var/log/translationnotifications/digests.log",
			user => l10nupdate, # which user?
			weekday => 1, # Monday
			hour => 10,
			minute => 5,
			ensure => $ensure;
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

class misc::maintenance::tor_exit_node( $enabled = undef ) {
	cron {
		tor_exit_node_update:
			command => "php /usr/local/apache/common/multiversion/MWScript.php extensions/TorBlock/loadExitNodes.php aawiki --force > /dev/null",
			user => apache,
			minute => '*/20',
			ensure => $enabled ?{
				true => present,
				false => absent,
				default => $misc::maintenance::default_ensure
			};
	}
}

class misc::maintenance::echo_mail_batch( $enabled = undef ) {
	cron {
		echo_mail_batch:
			command => "/usr/local/bin/foreachwikiindblist /usr/local/apache/common/echowikis.dblist extensions/Echo/processEchoEmailBatch.php",
			user => apache,
			minute => 0,
			hour => 0,
			ensure => $enabled ?{
				true => present,
				false => absent,
				default => $misc::maintenance::default_ensure
			};
	}
}

class misc::maintenance::update_flaggedrev_stats( $enabled = undef ) {
	file {
		"/usr/local/apache/common/php/extensions/FlaggedRevs/maintenance/wikimedia-periodic-update.sh":
			source => "puppet:///files/misc/scripts/wikimedia-periodic-update.sh",
			owner => apache,
			group => wikidev,
			mode => 0755,
			ensure => present;
	}

	cron {
		update_flaggedrev_stats:
			command => "/usr/local/apache/common/php/extensions/FlaggedRevs/maintenance/wikimedia-periodic-update.sh > /dev/null",
			user => "apache",
			hour => "*/2",
			minute => "0",
			ensure => $enabled ?{
				true => present,
				false => absent,
				default => $misc::maintenance::default_ensure
			};
	}
}

class misc::maintenance::cleanup_upload_stash( $enabled = undef ) {
	cron {
		cleanup_upload_stash:
			command => "/usr/local/bin/foreachwiki maintenance/cleanupUploadStash.php > /dev/null",
			user => "apache",
			hour => 1,
			minute => 0,
			ensure => $enabled ?{
				true => present,
				false => absent,
				default => $misc::maintenance::default_ensure
			};
	}
}

class misc::maintenance::update_special_pages( $enabled = undef ) {
	cron {
		update_special_pages:
			command => "flock -n /var/lock/update-special-pages /usr/local/bin/update-special-pages > /home/wikipedia/logs/norotate/updateSpecialPages.log 2>&1",
			user => "apache",
			monthday => "*/3",
			hour => 5,
			minute => 0,
			ensure => $enabled ?{
				true => present,
				false => absent,
				default => $misc::maintenance::default_ensure
			};
		update_special_pages_small:
			ensure => absent;
	}

	file {
		"/usr/local/bin/update-special-pages":
			source => "puppet:///files/misc/scripts/update-special-pages",
			owner => apache,
			group => wikidev,
			mode => 0755,
			ensure => present;
		"/usr/local/bin/update-special-pages-small":
			ensure => absent;
	}
}

class misc::maintenance::wikidata( $enabled = undef ) {
	$ensure = $enabled ?{
		true => present,
		false => absent,
		default => $misc::maintenance::default_ensure
	}

	cron {
		wikibase-repo-prune:
			command => "/usr/local/bin/mwscript extensions/Wikibase/repo/maintenance/pruneChanges.php --wiki wikidatawiki --number-of-days=3 2>&1 >> /var/log/wikidata/prune.log",
			user => mwdeploy,
			minute => [0,15,30,45],
			ensure => $ensure;

		# Run the dispatcher script every 5 minutes
		# This handles inserting jobs into client job queue, which then process the changes
		wikibase-dispatch-changes:
			command => "/usr/local/bin/mwscript extensions/Wikibase/lib/maintenance/dispatchChanges.php --wiki wikidatawiki --max-time 900 --batch-size 200 --dispatch-interval 30 2>&1 >> /var/log/wikidata/dispatcher.log",
			user => mwdeploy,
			minute => "*/5",
			ensure => $ensure;

        wikibase-dispatch-changes2:
			command => "/usr/local/bin/mwscript extensions/Wikibase/lib/maintenance/dispatchChanges.php --wiki wikidatawiki --max-time 900 --batch-size 200 --dispatch-interval 30 2>&1 >> /var/log/wikidata/dispatcher2.log",
			user => mwdeploy,
			minute => "*/5",
			ensure => $ensure;

		wikibase-poll-test2:
			ensure => absent;

		wikibase-poll-huwiki:
			ensure => absent;
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

class misc::maintenance::parsercachepurging( $enabled = undef ) {

	system_role { "misc::maintenance::parsercachepurging": description => "Misc - Maintenance Server: parser cache purging" }

	cron { 'parser_cache_purging':
		user => apache,
		minute => 0,
		hour => 1,
		weekday => 0,
		# Purge entries older than 30d * 86400s/d = 2592000s
		command => '/usr/local/bin/mwscript purgeParserCache.php --wiki=aawiki --age=2592000 >/dev/null 2>&1',
		ensure => $enabled ?{
			true => present,
			false => absent,
			default => $misc::maintenance::default_ensure
		};
	}

}

class misc::maintenance::geodata( $enabled = undef ) {
	file {
		"/usr/local/bin/update-geodata":
			ensure => present,
			source => "puppet:///files/misc/scripts/update-geodata",
			mode => 0555;
		"/usr/local/bin/clear-killlist":
			ensure => present,
			source => "puppet:///files/misc/scripts/clear-killlist",
			mode => 0555;
	}

	$ensure = $enabled ?{
		true => present,
		false => absent,
		default => $misc::maintenance::default_ensure
	}

	cron {
		"update-geodata":
			command => "/usr/local/bin/update-geodata >/dev/null",
			user => apache,
			minute => "*/30",
			ensure => $ensure;
		"clear-killlist":
			command => "/usr/local/bin/clear-killlist >/dev/null",
			user => apache,
			hour => 8,
			minute => 45,
			ensure => $ensure;
	}
}

