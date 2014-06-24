# = Class: role::wikimania_scholarships
#
# This class sets up the Wikimania Scholarships application
#
class role::wikimania_scholarships {

    class { '::wikimania_scholarships':
        # Opening date for 2014 application cycle
        open_date    => '2014-01-06T00:00:00Z',
        # Closing date for 2014 application cycle
        close_date   => '2014-02-17T23:59:59Z',
        hostname     => 'scholarships.wikimedia.org',
        deploy_dir   => '/srv/deployment/scholarships/scholarships',
        cache_dir    => '/var/cache/scholarships',
        # Send logs to fluorine
        udp2log_dest => '10.64.0.21:8420',
        serveradmin  => 'root@wikimedia.org',
        # Misc MySQL shard
        mysql_host   => 'm2-master.eqiad.wmnet',
        mysql_db     => 'scholarships',
        smtp_host    => $::mail_smarthost[0],
    }

    ferm::service { 'scholarships_http':
        proto   => 'tcp',
        port    => '80',
    }

}
# vim:sw=4 ts=4 sts=4 et:
