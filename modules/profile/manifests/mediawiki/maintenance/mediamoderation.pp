# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::mediamoderation(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'trust-and-safety-product'

    # push periodically-computed metrics into statsd (T353703)
    profile::mediawiki::periodic_job { 'mediamoderation-updateMetrics':
        command               => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/all.dblist extensions/MediaModeration/maintenance/updateMetrics.php --verbose',
        interval              => '*-*-* 04:32:00',
        cron_schedule         => '32 4 * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'updateMetrics.php',
        description           => 'push periodically-computed media moderation metrics into statsd at 04:32',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    # Run a scan over newly uploaded images on all WMF wikis (except Wikimedia Commons) every hour (T355169)
    profile::mediawiki::periodic_job { 'mediamoderation-hourlyScan':
        command               => '/usr/local/bin/foreachwikiindblist "all.dblist - mediamoderation-continuous-scan.dblist - preinstall.dblist" extensions/MediaModeration/maintenance/scanFilesInScanTable.php --use-jobqueue --sleep=1 --poll-sleep=10 --last-checked=never --verbose',
        interval              => '*-*-* *:02:00',
        cron_schedule         => '2 * * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'scanFilesInScanTable.php',
        description           => 'Run a scan over newly uploaded images on all WMF wikis (except Wikimedia Commons) at 2 minutes past the hour, every hour (T355169)',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    # Run a continuous scan on Wikimedia Commons, restarted every hour (T355169)
    profile::mediawiki::periodic_job { 'mediamoderation-continuousScan-commonswiki':
        command  => 'timeout 3500 /usr/local/bin/mwscript extensions/MediaModeration/maintenance/scanFilesInScanTable.php --wiki=commonswiki --use-jobqueue --poll-sleep=30 --sleep=60 --last-checked=never --verbose',
        interval => '*-*-* *:34:00',
    }
}
