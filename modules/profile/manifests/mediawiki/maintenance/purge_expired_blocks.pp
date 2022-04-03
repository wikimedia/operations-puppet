# == Class: profile::mediawiki::maintenance::purge_expired_blocks
#
# Provisions a periodic job which runs once a day on small wikis and which purges the
# expired blocks. In small wikis with very low traffic, expired local blocks may rarely
# be purged. To prevent temporary local blocks from lasting much longer than intended,
# we ensure that expired blocks are purged at least once a day in these small wikis.
# See T257473.
#
class profile::mediawiki::maintenance::purge_expired_blocks {
    profile::mediawiki::periodic_job { 'purge_expired_blocks':
        command  => '/usr/local/bin/foreachwikiindblist /srv/mediawiki/dblists/small.dblist maintenance/purgeExpiredBlocks.php',
        interval => '05:00'
    }
}
