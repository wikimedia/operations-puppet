# SPDX-License-Identifier: Apache-2.0
# T320403
class profile::mediawiki::maintenance::campaignevents(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    # team label for alerting
    $team_label = 'campaigns-product'

    # group0: meta.wikimedia.org both in beta and production
    profile::mediawiki::periodic_job { 'campaignevents-updateutcts-metawiki':
        command               => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/UpdateUTCTimestamps.php --wiki metawiki',
        interval              => '02:52',
        cron_schedule         => '52 2 * * *',
        team                  => $team_label,
        script_label          => 'UpdateUTCTimestamps.php-metawiki',
        description           => 'Update UTC Timestamps on metawiki',
        kubernetes            => true,
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
    profile::mediawiki::periodic_job { 'campaignevents-aggregateanswers-metawiki':
        command                => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/AggregateParticipantAnswers.php --wiki metawiki',
        interval               => '00/03:00',
        cron_schedule          => '0 */3 * * *',
        splay                  => 300,
        team                   => $team_label,
        script_label           => 'AggregateParticipantAnswers.php-metawiki',
        description            => 'Aggregate participant answers on metawiki',
        kubernetes             => true,
        helmfile_defaults_dir  => $helmfile_defaults_dir,
        migration_title        => 'campaignevents-aggregateparticipantanswers-metawiki',
        failedjobshistorylimit => 3, # Keep last 3 failures
        mesh_check_skip        => true,

    }

    unless $::realm == 'labs' {
        # group0: test.wikipedia.org
        profile::mediawiki::periodic_job { 'campaignevents-updateutcts-testwiki':
            command               => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/UpdateUTCTimestamps.php --wiki testwiki',
            interval              => '03:12',
            cron_schedule         => '12 3 * * *',
            team                  => $team_label,
            script_label          => 'UpdateUTCTimestamps.php-testwiki',
            description           => 'Update UTC Timestamps on testwiki',
            kubernetes            => true,
            helmfile_defaults_dir => $helmfile_defaults_dir,
        }
        profile::mediawiki::periodic_job { 'campaignevents-aggregateanswers-testwiki':
            command               => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/AggregateParticipantAnswers.php --wiki testwiki',
            interval              => '00/03:00',
            cron_schedule         => '0 */3 * * *',
            splay                 => 300,
            team                  => $team_label,
            script_label          => 'AggregateParticipantAnswers.php-testwiki',
            description           => 'Aggregate participant answers on testwiki',
            kubernetes            => true,
            helmfile_defaults_dir => $helmfile_defaults_dir,
            migration_title       => 'campaignevents-aggregateparticipantanswers-testwiki',
            mesh_check_skip       => true,
        }

        # group0: office.mediawiki.org
        profile::mediawiki::periodic_job { 'campaignevents-updateutcts-officewiki':
            command               => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/UpdateUTCTimestamps.php --wiki officewiki',
            interval              => '03:32',
            cron_schedule         => '32 3 * * *',
            team                  => $team_label,
            script_label          => 'UpdateUTCTimestamps.php-officewiki',
            description           => 'Update UTC Timestamps on officewiki',
            kubernetes            => true,
            helmfile_defaults_dir => $helmfile_defaults_dir,
        }
        profile::mediawiki::periodic_job { 'campaignevents-aggregateanswers-officewiki':
            command               => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/AggregateParticipantAnswers.php --wiki officewiki',
            interval              => '00/03:00',
            cron_schedule         => '0 */3 * * *',
            splay                 => 300,
            team                  => $team_label,
            script_label          => 'AggregateParticipantAnswers.php-officewiki',
            description           => 'Aggregate participant answers on officewiki',
            kubernetes            => true,
            helmfile_defaults_dir => $helmfile_defaults_dir,
            migration_title       => 'campaignevents-aggregateparticipantanswers-officewiki',
            mesh_check_skip       => true,
        }

        # group1: test2.wikipedia.org
        profile::mediawiki::periodic_job { 'campaignevents-updateutcts-test2wiki':
            command               => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/UpdateUTCTimestamps.php --wiki test2wiki',
            interval              => '03:52',
            cron_schedule         => '52 3 * * *',
            team                  => $team_label,
            script_label          => 'UpdateUTCTimestamps.php-test2wiki',
            description           => 'Update UTC Timestamps on test2wiki',
            kubernetes            => true,
            helmfile_defaults_dir => $helmfile_defaults_dir,
        }
        profile::mediawiki::periodic_job { 'campaignevents-aggregateanswers-test2wiki':
            command               => '/usr/local/bin/mwscript extensions/CampaignEvents/maintenance/AggregateParticipantAnswers.php --wiki test2wiki',
            interval              => '00/03:00',
            cron_schedule         => '0 */3 * * *',
            splay                 => 300,
            team                  => $team_label,
            script_label          => 'AggregateParticipantAnswers.php-test2wiki',
            description           => 'Aggregate participant answers on test2wiki',
            kubernetes            => true,
            helmfile_defaults_dir => $helmfile_defaults_dir,
            migration_title       => 'campaignevents-aggregateparticipantanswers-test2wiki',
            mesh_check_skip       => true,
        }
    }
}
