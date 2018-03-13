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

    # Previous weekly restarts.  Should be maintained for 3.5 days after
    # starting the new semiweekly schedule below, to avoid edge cases where the
    # shifting times could leave a node's varnish up for ~10 days during the
    # transition time.  Will cause a total of 3 restarts per week until
    # removed, and we'll need to double-check their timing manually to make
    # sure this one isn't dangerously close to one of the ones below.
    $times_w = cron_splay($all_nodes, 'weekly', "${cache_cluster}-backend-restarts")
    $be_restart_h = $times_w['hour']
    $be_restart_m = $times_w['minute']
    $be_restart_d = $times_w['weekday']

    # New semiweekly cron entries for restarts every 3.5 days
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
