# SPDX-License-Identifier: Apache-2.0
# This file will be removed in favor of testkitchen.pp
class profile::mediawiki::maintenance::experimentationlab(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'experiment-platform'

    profile::mediawiki::periodic_job { 'experimentationlab-UpdateConfigs':
        ensure                => 'absent',

        # mwscript requires the wiki parameter but the maintenance script is wiki-agnostic.
        command               => '/usr/local/bin/mwscript extensions/MetricsPlatform/maintenance/UpdateConfigs.php --wiki aawiki',

        interval              => '*:*:00',
        cron_schedule         => '* * * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'MetricsPlatform-UpdateConfigs.php',
        description           => 'Fetch instrument and experiment configs from xLab and updates the backing store if they have changed',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
