# = Class: role::wikimania_scholarships
#
# This class sets up the Wikimania Scholarships application
#
class role::wikimania_scholarships {

    class { '::wikimania_scholarships':
        # Opening date for 2014 application cycle
        open_date   => '2014-01-01T00:00:00Z',
        # Closing date for 2014 application cycle
        close_date  => '2014-02-28T23:59:59Z',
        hostname    => 'scholarships.wikimedia.org',
        deploy_dir  => '/srv/deployment/scholarships/scholarships',
        logs_dir    => '/var/log/scholarships',
        serveradmin => 'root@wikimedia.org',
        # Misc MySQL shard
        mysql_host  => 'db1001.eqiad.wmnet',
        mysql_db    => 'scholarships',
        smtp_host   => 'smtp.pmtpa.wmnet'
    }

}
# vim:sw=4 ts=4 sts=4 et:
