define profile::multidc_redis::instances(
    $ip,
    $settings = {},
    $shards = {},
    $discovery = undef,
    $aof = false,
) {
    $replica_state_file = "/etc/redis/replica/${title}-state.conf"

    if $aof {
        $base_settings = {
            appendfilename => "${::hostname}-${title}.aof",
            dbfilename     => "${::hostname}-${title}.rdb",
            'include'                   => $replica_state_file,
        }
    } else {
        $base_settings = {
            dbfilename     => "${::hostname}-${title}.rdb",
            'include'                   => $replica_state_file,
        }
    }

    redis::instance { $title:
        settings => merge($base_settings, $settings)
    }

    if $discovery {
        confd::file { $replica_state_file:
            ensure     => present,
            prefix     => "/discovery/${discovery}",
            watch_keys => ['/'],
            content    => template('profile/jobqueue_redis/statefile.tpl.erb'),
        }
        Base::Service_unit['confd'] -> Base::Service_unit["redis-instance-tcp_${title}"]

    }
}
