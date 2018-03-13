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

    # Semiweekly cron entries for restarts every 3.5 days
    $times_a = cron_splay($all_nodes, 'semiweekly-a', "${cache_cluster}-backend-restarts-semiweekly")
    $be_restart_a_h = $times_a['hour']
    $be_restart_a_m = $times_a['minute']
    $be_restart_a_d = $times_a['weekday']
    $times_b = cron_splay($all_nodes, 'semiweekly-b', "${cache_cluster}-backend-restarts-semiweekly")
    $be_restart_b_h = $times_b['hour']
    $be_restart_b_m = $times_b['minute']
    $be_restart_b_d = $times_b['weekday']

    file { '/etc/cron.d/varnish-backend-restart':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('cacheproxy/varnish-backend-restart.cron.erb'),
        require => File['/usr/local/sbin/varnish-backend-restart'],
    }
}
