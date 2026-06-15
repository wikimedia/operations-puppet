# SPDX-License-Identifier: Apache-2.0
class profile::mediawiki::maintenance::abstractwiki_update_generated_articles(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    $team = 'abstract-wikipedia'

    profile::mediawiki::periodic_job { 'abstractwiki_update_generated_articles':
        command               => '/usr/local/bin/mwscript extensions/WikiLambda/maintenance/updateAbstractWikiArticleStore.php --wiki abstractwiki',
        cron_schedule         => '17 00 * * MON',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'UpdateAbstractWikiArticleStore.php-weekly-refresh',
        description           => 'For each configured abstract article in each configured language, load the Abstract Wikipedia content and store the available generated results in the content store. Missing and stale fragments are triggered to be run on Wikifunctions, but not waited for.',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }

    profile::mediawiki::periodic_job { 'abstractwiki_update_pending_fragments':
        command               => '/usr/local/bin/mwscript extensions/WikiLambda/maintenance/updateAbstractWikiArticleStore.php --wiki abstractwiki --pending',
        cron_schedule         => '27 * * * MON',
        kubernetes            => true,
        team                  => $team,
        script_label          => 'UpdateAbstractWikiArticleStore.php-update-pending-fragments',
        description           => 'For outstanding pending fragments from the weekly run, check to see if they are now available and if so stash them in the content store.',
        helmfile_defaults_dir => $helmfile_defaults_dir,
    }
}
