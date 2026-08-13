# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::tk_constructive_edits(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'editing'

    profile::mediawiki::periodic_job { 'testKitchen-ConstructiveEdits':
        # Closed wikis cannot be edited. Private and fishbowl wikis stay out of the
        # event stream. Same dblist as WikimediaEvents UpdatePeriodicMetrics.
        #
        # The script aligns its range to the interval, using the time it starts. The
        # shell expands --as-of once, before the loop, so every wiki gets the same
        # range. Without it, a pass that crosses the hour gives the wikis after the
        # boundary the next range, and their previous one is never reported.
        command                   => '/usr/local/bin/foreachwikiindblist "all - closed - private - fishbowl" extensions/WikimediaEvents/maintenance/InstrumentConstructiveEdits.php --threshold=48 --interval=1 --as-of="$(date -u +%Y%m%d%H%M%S)"',
        cron_schedule             => '18 * * * *',
        kubernetes                => true,
        team                      => $team,
        script_label              => 'TestKitchen-InstrumentConstructiveEdits.php',
        description               => 'Instrument constructive edits via Test Kitchen',
        helmfile_defaults_dir     => $helmfile_defaults_dir,
        # The loop aborts on the first wiki that fails, which costs every later wiki
        # its hour. The events are append-only, so a lost hour needs a replay with
        # --as-of. Skip the failing wiki instead.
        foreachwiki_ignore_errors => true,
    }
}
