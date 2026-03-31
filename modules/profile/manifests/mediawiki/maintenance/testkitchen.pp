# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::testkitchen(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'experiment-platform'

    # The extensions/TestKitchen/maintenance/UpdateConfigs.php maintenance script is sensitive
    # to wiki group, i.e. group0, group1, and group2. The script uses a hard-coded version
    # number to handle (rare) backwards-incompatible changes in the upstream API. As the wiki
    # groups are updated across the week, we can have situations like a group0 wiki using
    # version 1, and group1 and group2 wikis using version 2. We run the script for a group0
    # and group2 wiki so that, in the case of a version bump, both versions are used as the
    # wiki groups are updated across the week.

    profile::mediawiki::periodic_job { 'testkitchen-UpdateConfigs':
        ensure                => absent,
        command               => '/usr/local/bin/mwscript extensions/TestKitchen/maintenance/UpdateConfigs.php --wiki testwiki',
        interval              => '*:*:00',
        cron_schedule         => '* * * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'TestKitchen-UpdateConfigs.php-group0',
        description           => 'Fetch instrument and experiment configs from Test Kitchen and updates the backing store if they have changed',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    profile::mediawiki::periodic_job { 'testkitchen-UpdateConfigs-group0':
        command               => '/usr/local/bin/mwscript extensions/TestKitchen/maintenance/UpdateConfigs.php --wiki testwiki',
        interval              => '*:*:00',
        cron_schedule         => '* * * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'TestKitchen-UpdateConfigs.php-group0',
        description           => 'Fetch instrument and experiment configs from Test Kitchen and updates the backing store if they have changed',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    profile::mediawiki::periodic_job { 'testkitchen-UpdateConfigs-group2':
        command               => '/usr/local/bin/mwscript extensions/TestKitchen/maintenance/UpdateConfigs.php --wiki aawiki',
        interval              => '*:*:00',
        cron_schedule         => '* * * * *',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'TestKitchen-UpdateConfigs.php-group2',
        description           => 'Fetch instrument and experiment configs from Test Kitchen and updates the backing store if they have changed',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
