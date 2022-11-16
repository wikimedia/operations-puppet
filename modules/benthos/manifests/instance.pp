# SPDX-License-Identifier: Apache-2.0
# == define: benthos::instance
#
# Deploy a self-contained Benthos instance.
#
define benthos::instance(
    String $config,
    Stdlib::Port $port,
    Hash[String, Any] $env_variables = undef,
    Wmflib::Ensure $ensure = present,
) {

    require benthos

    $config_path = "/etc/benthos/${title}.yaml"
    $env_config_path = "/etc/benthos/${title}.env"
    $exec_path = '/usr/bin/benthos'

    file { $config_path:
        ensure       => stdlib::ensure($ensure, 'file'),
        owner        => 'benthos',
        group        => 'benthos',
        mode         => '0755',
        content      => $config,
        validate_cmd => '/usr/bin/benthos lint %',
    }

    if $env_variables {
        file { $env_config_path:
            ensure  => stdlib::ensure($ensure, 'file'),
            owner   => 'benthos',
            group   => 'benthos',
            mode    => '0755',
            content => template('benthos/env_variables.erb'),
        }
    }

    systemd::service { "benthos@${title}":
        ensure  => present,
        content => systemd_template('benthos@'),
        restart => true,
        require => File[$config_path],
    }

    systemd::service { "benthos@-${title}":
        ensure  => absent,
        content => systemd_template('benthos@'),
    }
}
