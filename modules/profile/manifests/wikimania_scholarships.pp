# = Class: profile::wikimania_scholarships
#
# This class sets up the Wikimania Scholarships application
#
class profile::wikimania_scholarships(
    Stdlib::Fqdn $db_host = lookup('profile::wikimania_scholarships::db_host'),
) {

    class { '::wikimania_scholarships':
        hostname     => 'scholarships.wikimedia.org',
        deploy_dir   => '/srv/deployment/scholarships/scholarships',
        cache_dir    => '/var/cache/scholarships',
        udp2log_host => 'mwlog1002.eqiad.wmnet',
        udp2log_port => 8420,
        serveradmin  => 'noc@wikimedia.org',
        # Misc MySQL shard
        mysql_host   => $db_host,
        mysql_db     => 'scholarships',
        smtp_host    => 'localhost',
    }
}
# vim:sw=4 ts=4 sts=4 et:
