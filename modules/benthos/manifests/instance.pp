# SPDX-License-Identifier: Apache-2.0
# == define: benthos::instance
#
# Deploy a self-contained Benthos instance.
#
# Please note: the 'port' parameter is used by prometheus to figure out which ports to scrape,
# even if it's unused here.
#
define benthos::instance(
    String $config_source,
    Stdlib::Port $port,
    Hash[String, Any] $env_variables = undef,
    Wmflib::Ensure $ensure = present,
) {

    require benthos

    $config_path = "/etc/benthos/${title}.yaml"
    $env_config_path = "/etc/benthos/${title}.env"
    $exec_path = '/usr/bin/benthos'
    $service_name = "benthos@${title}"

    file { $config_path:
        ensure       => stdlib::ensure($ensure, 'file'),
        owner        => 'benthos',
        group        => 'benthos',
        mode         => '0755',
        source       => "puppet:///modules/${config_source}",
        validate_cmd => '/usr/bin/benthos lint --skip-env-var-check %',
    }

    if $env_variables {
        file { $env_config_path:
            ensure  => stdlib::ensure($ensure, 'file'),
            owner   => 'benthos',
            group   => 'benthos',
            mode    => '0755',
            content => template('benthos/env_variables.erb'),
            notify  => Service[$service_name],
        }
    }

    systemd::service { $service_name:
        ensure  => $ensure,
        content => systemd_template('benthos@'),
        restart => true,
        require => File[$config_path],
    }

    profile::auto_restarts::service { $service_name:
        ensure => $ensure,
    }
}
