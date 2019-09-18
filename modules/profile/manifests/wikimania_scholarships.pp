# = Class: profile::wikimania_scholarships
#
# This class sets up the Wikimania Scholarships application
#
class profile::wikimania_scholarships(
    $db_host = lookup('profile::wikimania_scholarships::db_host'),
) {

    class { '::wikimania_scholarships':
        hostname     => 'scholarships.wikimedia.org',
        deploy_dir   => '/srv/deployment/scholarships/scholarships',
        cache_dir    => '/var/cache/scholarships',
        udp2log_dest => 'mwlog1001.eqiad.wmnet:8420',
        serveradmin  => 'noc@wikimedia.org',
        # Misc MySQL shard
        mysql_host   => $db_host,
        mysql_db     => 'scholarships',
        smtp_host    => 'localhost',
    }

    ferm::service { 'scholarships_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }

}
# vim:sw=4 ts=4 sts=4 et:
