# SPDX-License-Identifier: Apache-2.0
# == Class: pyrra::filesystem
#
# Pyrra filesystem operator and backend for the API.
#
# = Parameters
# [*config_files*] The folder where Pyrra finds the config files to use.
# [*prometheus_folder*] The folder where Pyrra writes the generated Prometheus rules and alerts.
# [*prometheus_url*] The URL to the Prometheus to query

class pyrra::filesystem(
    String $prometheus_url    = 'http://localhost:17902/rule/', # issue reloads to local thanos rule T364645
    String $config_files      = '/etc/pyrra/config/*.yaml',
    String $prometheus_folder = '/etc/pyrra/output-rules/',
){

    ensure_packages(['pyrra'])

    $config_folder = dirname($config_files)

    file { [ $prometheus_folder, $config_folder ]:
        ensure  => directory,
        mode    => '0755',
        owner   => 'pyrra',
        group   => 'pyrra',
        require => Package['pyrra'],
    }

    systemd::service { 'pyrra-filesystem':
        ensure         => present,
        restart        => true,
        override       => true,
        content        => systemd_template('pyrra-filesystem'),
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }

    systemd::unit { 'pyrra-filesystem-notify-thanos.path':
        ensure  => absent,
        restart => true,
        content => systemd_template('pyrra-filesystem-notify-thanos'),
    }

}
