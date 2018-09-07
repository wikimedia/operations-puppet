# patched version of pt-kill and configuration
#
# This profile installs the config file for wmf-kill-wmf
# as well the wmf-pt-kill contains the systemd service and the patched script itself
#
#
class profile::labs::db::kill_long_running_queries (
    $victim        = hiera(profile::labs::db::kill_long_running_queries::pt_kill_victim,),
    $interval      = hiera(profile::labs::db::kill_long_running_queries::pt_kill_interval,),
    $busy_time     = hiera(profile::labs::db::kill_long_running_queries::pt_kill_busy_time,),
    $match_command = hiera(profile::labs::db::kill_long_running_queries::pt_kill_match_command,),
    $match_user    = hiera(profile::labs::db::kill_long_running_queries::pt_kill_match_user,),
    $log           = hiera(profile::labs::db::kill_long_running_queries::pt_kill_log,),
    $socket        = hiera(profile::labs::db::kill_long_running_queries::pt_kill_socket,),
){
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
