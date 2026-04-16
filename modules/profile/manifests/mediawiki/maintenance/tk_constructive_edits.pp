# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::tk_constructive_edits(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'editing'

    profile::mediawiki::periodic_job { 'testKitchen-ConstructiveEdits':
        command               => '/usr/local/bin/foreachwiki extensions/WikimediaEvents/maintenance/InstrumentConstructiveEdits.php --threshold=48 --interval=1',
        cron_schedule         => '18 * * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'TestKitchen-InstrumentConstructiveEdits.php',
        description           => 'Instrument constructive edits via Test Kitchen',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
