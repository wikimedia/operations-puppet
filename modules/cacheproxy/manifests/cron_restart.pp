# == Class cacheproxy::cron_restart
#
# Add a periodic restart every 3.5 days via cron, staggering the time across a
# cluster
#
# === Parameters
#
# [*nodes*] The list of nodes we need to stagger restarts across.
#
class cacheproxy::cron_restart ($nodes, $cache_cluster, $datacenters) {
    $all_nodes = sort($datacenters.reduce([]) |Array $memo, String $dc| {
        $memo + pick($nodes[$dc], []) + pick($nodes["${dc}_ats"], [])
    })

    # Semiweekly cron entries for restarts every 3.5 days
    $times = cron_splay($all_nodes, 'semiweekly', "${cache_cluster}-backend-restarts")
    $be_restart_a_h = $times['hour-a']
    $be_restart_a_m = $times['minute-a']
    $be_restart_a_d = $times['weekday-a']
    $be_restart_b_h = $times['hour-b']
    $be_restart_b_m = $times['minute-b']
    $be_restart_b_d = $times['weekday-b']

    file { '/etc/cron.d/varnish-backend-restart':
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('cacheproxy/varnish-backend-restart.cron.erb'),
        require => File['/usr/local/sbin/varnish-backend-restart'],
    }
}
