# = Class: role::wikimania_scholarships
#
# This class sets up the Wikimania Scholarships application
#
class role::wikimania_scholarships {

    include base::firewall

    class { '::wikimania_scholarships':
        hostname     => 'scholarships.wikimedia.org',
        deploy_dir   => '/srv/deployment/scholarships/scholarships',
        cache_dir    => '/var/cache/scholarships',
        # Send logs to fluorine
        udp2log_dest => '10.64.0.21:8420',
        serveradmin  => 'noc@wikimedia.org',
        # Misc MySQL shard
        mysql_host   => 'm2-master.eqiad.wmnet',
        mysql_db     => 'scholarships',
        smtp_host    => $::mail_smarthost[0],
    }

    ferm::service { 'scholarships_http':
        proto => 'tcp',
        port  => '80',
    }

    scap::target { 'wikimedia/wikimania-scholarships':
        service_name => 'scholarships',
        deploy_user  => 'deploy-service'
    }

}
# vim:sw=4 ts=4 sts=4 et:
