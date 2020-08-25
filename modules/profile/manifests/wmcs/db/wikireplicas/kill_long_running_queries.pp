# patched version of pt-kill and configuration
#
# This profile installs the config file for wmf-kill-wmf
# as well the wmf-pt-kill contains the systemd service and the patched script itself
#
#
class profile::wmcs::db::wikireplicas::kill_long_running_queries (
    $victims        = lookup(profile::wmcs::db::wikireplicas::kill_long_running_queries::pt_kill_victims,),
    $interval       = lookup(profile::wmcs::db::wikireplicas::kill_long_running_queries::pt_kill_interval,),
    $busy_time      = lookup(profile::wmcs::db::wikireplicas::kill_long_running_queries::pt_kill_busy_time,),
    $match_command  = lookup(profile::wmcs::db::wikireplicas::kill_long_running_queries::pt_kill_match_command,),
    $match_user     = lookup(profile::wmcs::db::wikireplicas::kill_long_running_queries::pt_kill_match_user,),
    $log            = lookup(profile::wmcs::db::wikireplicas::kill_long_running_queries::pt_kill_log,),
    $socket         = lookup(profile::wmcs::db::wikireplicas::kill_long_running_queries::pt_kill_socket,),
){
    require ::profile::wmcs::db::scriptconfig

    file { '/etc/default/wmf-pt-kill':
        ensure  => file,
        content => template('role/mariadb/wmf-pt-kill.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
    }
    package { 'wmf-pt-kill':
        ensure => present,
    }
    service { 'wmf-pt-kill':
        ensure => running,
    }

}
