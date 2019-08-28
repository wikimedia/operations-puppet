# = Class: profile::iegreview
#
# This class provisions the IEG grant review application.
#
class profile::iegreview {

    class { '::iegreview':
        hostname   => 'iegreview.wikimedia.org',
        deploy_dir => '/srv/deployment/iegreview/iegreview',
        cache_dir  => '/var/cache/iegreview',
        # Send logs to udp2log relay
        log_dest   => 'udp://udplog.eqiad.wmnet:8420/iegreview',
        # Misc MySQL shard
        mysql_host => 'm2-master.eqiad.wmnet',
        mysql_db   => 'iegreview',
        smtp_host  => 'localhost',
    }

    ferm::service { 'iegreview_http':
        proto  => 'tcp',
        port   => '80',
        srange => '$CACHES',
    }

    require_package('mysql-client')
}
# vim:sw=4 ts=4 sts=4 et:
