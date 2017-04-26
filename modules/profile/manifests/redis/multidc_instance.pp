define profile::redis::multidc_instance(
    $ip,
    $shards,
    $settings = {},
    $discovery = undef,
    $aof = false,
) {
    $replica_state_file = "/etc/redis/replica/${title}-state.conf"

    if $aof {
        $base_settings = {
            appendfilename => "${::hostname}-${title}.aof",
            dbfilename     => "${::hostname}-${title}.rdb",
            'include'      => $replica_state_file,
        }
    } else {
        $base_settings = {
            dbfilename => "${::hostname}-${title}.rdb",
            'include'  => $replica_state_file,
        }
    }

    ::redis::instance { $title:
        settings => merge($base_settings, $settings)
    }

    if $discovery {
        file { "${replica_state_file}.inc":
            ensure   => present,
            owner    => 'root',
            group    => 'root',
            template => template('profile/redis/multidc_statefile.inc.erb'),
            before   => Confd::File[$replica_state_file]
        }
        confd::file { $replica_state_file:
            ensure     => present,
            prefix     => "/discovery/${discovery}",
            watch_keys => ['/'],
            content    => template('profile/redis/multidc_statefile.tpl.erb'),
        }
        Base::Service_unit['confd'] -> Base::Service_unit["redis-instance-tcp_${title}"]

    } else {
        file { $replica_state_file:
            ensure  => 'present',
            content => "# This is a placeholder file, do not remove\n",
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            before  => Base::Service_unit["redis-instance-tcp_${title}"]
        }
    }
}
