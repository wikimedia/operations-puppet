# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::wikimediaevents(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    # team label for alerting
    $team_label = 'trust-and-safety-product'

    profile::mediawiki::periodic_job { 'wikimediaevents-UpdatePeriodicMetrics-per-wiki':
        command               => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/all.dblist extensions/WikimediaEvents/maintenance/UpdatePeriodicMetrics.php --verbose',
        interval              => '*-*-* 04:40:00',
        cron_schedule         => '40 4 * * *',
        team                  => $team_label,
        script_label          => 'UpdatePeriodicMetrics.php-per-wiki',
        description           => 'Calculate per-wiki periodic metrics and let them be pulled by Prometheus (T375508)',
        kubernetes            => true,
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    profile::mediawiki::periodic_job { 'wikimediaevents-UpdatePeriodicMetrics-global':
        command               => '/usr/local/bin/mwscript extensions/WikimediaEvents/maintenance/UpdatePeriodicMetrics.php --wiki=metawiki --global-metrics --verbose',
        interval              => '*-*-* 04:50:00',
        cron_schedule         => '50 4 * * *',
        team                  => $team_label,
        script_label          => 'UpdatePeriodicMetrics.php-global',
        description           => 'Calculate global periodic metrics and let them be pulled by Prometheus (T375508)',
        kubernetes            => true,
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
