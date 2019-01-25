# This cron will purge unpublished articles from ContentTranslation older than
# 455 days (--age-in-days). See: T183890.
class mediawiki::maintenance::purge_old_cx_drafts( $ensure = present ) {
    cron { 'purge-old-cx-drafts':
        ensure   => $ensure,
        user     => $::mediawiki::users::web,
        monthday => [3, 18],
        hour     => 10,
        minute   => 30,
        command  => '/usr/local/bin/foreachwikiindblist "/srv/mediawiki/dblists/wikipedia.dblist - /srv/mediawiki/dblists/special.dblist - /srv/mediawiki/dblists/closed.dblist" extensions/ContentTranslation/scripts/purge-unpublished-drafts.php --age-in-days=455 --really > /var/log/mediawiki/purge_old_cx_drafts.log 2>&1',
    }
}
