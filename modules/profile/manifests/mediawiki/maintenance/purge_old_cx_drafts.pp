# This periodic job will purge unpublished articles from ContentTranslation older than
# 455 days (--age-in-days) and notify users 30 days prior (--notify-age-in-days)
# See: T183890, T261189.
class profile::mediawiki::maintenance::purge_old_cx_drafts(
    Stdlib::Unixpath $helmfile_defaults_dir = lookup('profile::kubernetes::deployment_server::global_config::general_dir', {default_value => '/etc/helmfile-defaults'}),
) {
    # We use wikidataclient-test here in order to prevent running this
    # job against test2wiki, which isn't included in the testwiki
    # dblist
    profile::mediawiki::periodic_job { 'purge_old_cx_drafts':
        command                 => '/usr/local/bin/foreachwikiindblist "/srv/mediawiki/dblists/wikipedia.dblist - /srv/mediawiki/dblists/special.dblist - /srv/mediawiki/dblists/closed.dblist - /srv/mediawiki/dblists/wikidataclient-test.dblist - /srv/mediawiki/dblists/private.dblist" extensions/ContentTranslation/scripts/purge-unpublished-drafts.php --age-in-days=455 --notify-age-in-days=425 --really',
        interval                => '*-3,18 10:30',
        cron_schedule           => '30 10 3,18 * *',
        kubernetes              => true,
        team                    => 'language_and_product_localization',
        script_label            => 'purge-unpublished-drafts.php',
        description             => 'Purge unpublished articles from ContentTranslation older than 455 days, notifying users 30 days prior',
        helmfile_defaults_dir   => $helmfile_defaults_dir,
        ttlsecondsafterfinished => 1814400, # 3 weeks
    }
}
