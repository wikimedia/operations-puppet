# = Class: role::iegreview
#
# This class provisions the IEG grant review application.
#
class role::iegreview {

    class { '::iegreview':
        hostname     => 'iegreview.wikimedia.org',
        deploy_dir   => '/srv/deployment/iegreview/iegreview',
        cache_dir    => '/var/cache/iegreview',
        # Send logs to fluorine
        udp2log_dest => '10.64.0.21:8420',
        serveradmin  => 'root@wikimedia.org',
        # Misc MySQL shard
        mysql_host   => 'm2-master.eqiad.wmnet',
        mysql_db     => 'iegreview',
        smtp_host    => $::mail_smarthost[0],
    }

    ferm::service { 'iegreview_http':
        proto   => 'tcp',
        port    => '80',
    }
}
# vim:sw=4 ts=4 sts=4 et:
