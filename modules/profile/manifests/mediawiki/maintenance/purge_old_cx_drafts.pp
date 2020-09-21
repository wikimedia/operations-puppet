# This cron will purge unpublished articles from ContentTranslation older than
# 455 days (--age-in-days) and notify users 30 days prior (--notify-age-in-days)
# See: T183890, T261189.
class profile::mediawiki::maintenance::purge_old_cx_drafts {
    profile::mediawiki::periodic_job { 'purge_old_cx_drafts':
        command  => '/usr/local/bin/foreachwikiindblist "/srv/mediawiki/dblists/wikipedia.dblist - /srv/mediawiki/dblists/special.dblist - /srv/mediawiki/dblists/closed.dblist - /srv/mediawiki/dblists/testwikis.dblist - /srv/mediawiki/dblists/private.dblist" extensions/ContentTranslation/scripts/purge-unpublished-drafts.php --age-in-days=455 --notify-age-in-days=425 --really',
        interval => '*-3,18 10:30'
    }
}
