# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::mainstash_metrics(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'mediawiki-platform'

    profile::mediawiki::periodic_job { 'mainstash_metrics':
        command               => '/usr/local/bin/mwscript maintenance/reportObjectStashStats.php --wiki aawiki --report',
        cron_schedule         => '37 00 * * SUN',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'ReportObjectStashStats-weekly',
        description           => 'Calculate and report MainStash inventory metrics each week alongside flow (T430940)',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
