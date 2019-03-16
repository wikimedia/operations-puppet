# == Class: php::fpm
#
# Configures a running fpm daemon. You need to have the ::php class
# declared, and to include 'fpm' as one of the sapis in order to
# include this class.
#
# You need to define pools, you will need to use php::fpm::pool as we
# explicitly remove any pool configuration that's not managed
# explicitly in puppet.
#
# === Parameters
#
# [*ensure*] The usual metaparameter
#
# [*config*] A k => v hash of config keys and values we want to add to
#   the defaults.
#
class php::fpm(
    Wmflib::Ensure $ensure = 'present',
    Hash $config = {},
) {
    if !defined(Class['php']) {
        fail('php::fpm is not meant to be used before the php class is declared.')
    }
    # Now let's check the fpm sapi was declared
    unless 'fpm' in $php::sapis {
        fail('You need to declare fpm as a sapi in the php class to be able to use fpm')
    }


    $main_config_file = "${php::config_dir}/fpm/php-fpm.conf"
    # Default config values
    $default_config = {
        'error_log'               => 'syslog',
        'syslog.facility'         => 'daemon',
        'syslog.ident'            => "php${php::version}-fpm",
        'log_level'               => 'notice',
        'process_control_timeout' => 180,
        'systemd_interval'        => 10,
        'display_errors'          => 0,
    }

    # These config values are set by the systemd unit shipped by
    # debian and any change here won't change things, so better be
    # explicit.
    $immutable_config = {
        'pid'       => "/run/php/php${php::version}-fpm.pid",
        'daemonize' => 'no',
    }

    $full_global_config = merge($default_config, $config, $immutable_config)
    file { $main_config_file:
        ensure  => $ensure,
        content => template("php/php${php::version}-fpm.conf.erb"),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package["php${php::version}-fpm"]
    }

    # We want to reload php-fpm. It has been tested that a reload can manage the
    # following scenarios:
    # - Changes to the config (including adding and removing extensions)
    # - Reconfigure a pool
    if $ensure == 'present' {
        $service_name = "php${php::version}-fpm"
        service { $service_name:
            ensure    => running,
            provider  => 'systemd',
            restart   => "/bin/systemctl reload ${service_name}.service",
            subscribe => File[$main_config_file],
        }

        # Installing an extension should reload php-fpm
        Package<| tag == 'php::package::fpm' |> -> Service[$service_name]
        # Any config file should reload the service
        File<| tag == 'php::config::fpm' |> -> Service[$service_name]
    }

    # We want pools to be explicitly managed by puppet, and we don't want packages etc
    # to mess with it.
    file { "${php::config_dir}/fpm/pool.d":
        ensure  => ensure_directory($ensure),
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        purge   => true,
        require => Package["php${php::version}-fpm"]
    }
}
