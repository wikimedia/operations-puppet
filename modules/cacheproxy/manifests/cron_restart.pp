# == Class cacheproxy::cron_restart
#
# Add a periodic restart every week as a cron job, staggering the time across a
# cluster
#
# === Parameters
#
# [*nodes*] The list of nodes we need to stagger restarts across.
#
class cacheproxy::cron_restart ($nodes, $cache_cluster) {
    #TODO: maybe use the list of datacenters to do this?
    $all_nodes = array_concat($nodes['eqiad'], $nodes['esams'], $nodes['ulsfo'], $nodes['codfw'], $nodes['eqsin'])
    $times = cron_splay($all_nodes, 'weekly', "${cache_cluster}-backend-restarts")
    $be_restart_h = $times['hour']
    $be_restart_m = $times['minute']
    $be_restart_d = $times['weekday']

    file { '/etc/cron.d/varnish-backend-restart':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('cacheproxy/varnish-backend-restart.cron.erb'),
        require => File['/usr/local/sbin/varnish-backend-restart'],
    }
}
