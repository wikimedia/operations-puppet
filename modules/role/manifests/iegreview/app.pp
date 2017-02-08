# = Class: role::iegreview::app
#
# This class provisions the IEG grant review application.
#
class role::iegreview::app {

    include ::base::firewall

    class { '::iegreview':
        hostname   => 'iegreview.wikimedia.org',
        deploy_dir => '/srv/deployment/iegreview/iegreview',
        cache_dir  => '/var/cache/iegreview',
        # Send logs to udp2log relay
        log_dest   => 'udp://udplog.eqiad.wmnet:8420/iegreview',
        # Misc MySQL shard
        mysql_host => 'm2-master.eqiad.wmnet',
        mysql_db   => 'iegreview',
        smtp_host  => $::mail_smarthost[0],
    }

    ferm::service { 'iegreview_http':
        proto => 'tcp',
        port  => '80',
    }
}
# vim:sw=4 ts=4 sts=4 et:
