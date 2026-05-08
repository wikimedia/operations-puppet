# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::demote_ineligible_users(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'trust-and-safety-product'

    profile::mediawiki::periodic_job { 'demote_ineligible_users':
        command               => '/usr/local/bin/foreachwikiindblist sul maintenance/demoteIneligibleUsers.php --relay-log checkuser=metawiki --relay-log suppress=metawiki',
        interval              => 'Sun 21:37',
        cron_schedule         => '37 21 * * SUN',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'demoteIneligibleUsers.php-sul',
        description           => 'Demote members of restricted groups who no longer meet the group requirements',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    profile::mediawiki::periodic_job { 'demote_ineligible_users_nonsul':
        command               => '/usr/local/bin/foreachwikiindblist "all - sul" maintenance/demoteIneligibleUsers.php',
        interval              => 'Sun 21:37',
        cron_schedule         => '37 21 * * SUN',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'demoteIneligibleUsers.php-nonsul',
        description           => 'Demote members of restricted groups who no longer meet the group requirements',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    profile::mediawiki::periodic_job { 'demote_ineligible_central_users':
        command               => '/usr/local/bin/mwscript extensions/CentralAuth/maintenance/DemoteIneligibleCentralUsers.php --wiki metawiki',
        interval              => 'Sun 20:37',
        cron_schedule         => '37 20 * * SUN',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'DemoteIneligibleCentralUsers.php',
        description           => 'Demote members of restricted global groups who no longer meet the group requirements',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
