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
    Optional[Hash[String, Stdlib::Datasize]] $instances = lookup('profile::wmcs::db::wikireplicas::mariadb_multiinstance::instances', {default_value => undef}),
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
    if $instances {
        service { 'wmf-pt-kill':
            ensure => stopped,
            enable => 'mask',
        }
        file { '/etc/logrotate.d/wmf-pt-kill':
            ensure => absent,
        }

        $instances.each |$section, $buffer_pool| {
            $logfile = "/var/log/wmf-pt-kill/wmf-pt-kill-${section}.log"
            $instance_socket = "/var/run/mysqld/mysqld.${section}.sock"
            systemd::service { "wmf-pt-kill@${section}":
                ensure  => present,
                restart => true,
                content => systemd_template('wmcs/db/wikireplicas/wmf-pt-kill@'),
            }
            logrotate::rule { "wmf-pt-kill-${section}":
                ensure        => present,
                file_glob     => $logfile,
                frequency     => 'weekly',
                copy_truncate => true,
                missing_ok    => true,
                not_if_empty  => true,
                rotate        => 4,
                create        => '640 wmf-pt-kill wmf-pt-kill'
            }
        }
    } else {
        service { 'wmf-pt-kill':
            ensure => running,
        }
    }
}
